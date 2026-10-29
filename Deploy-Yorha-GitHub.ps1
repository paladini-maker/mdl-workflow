[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string]$RepositoryName = 'mdl-workflow',
    [ValidateSet('private','public')]
    [string]$Visibility = 'private',
    [ValidateRange(5,180)]
    [int]$WaitMinutes = 60,
    # Override opcional: publica en <Owner>/<RepositoryName> en lugar de <cuenta-autenticada>/<RepositoryName>.
    [string]$Owner = '',
    [switch]$SkipWorkflowWait
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Root = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$WorkflowFile = 'yorha-windows-auto-build.yml'
$WorkflowPath = Join-Path $Root '.github\workflows\yorha-windows-auto-build.yml'
$RunOutput = Join-Path $Root 'build\github-actions'
$null = New-Item -ItemType Directory -Path $RunOutput -Force
$script:LastStep = 'initialization'
$script:RepoFullName = $null
$script:OwnerName = $null
$script:RunId = $null
$script:ActualVisibility = $Visibility

function Write-Step([string]$Message) {
    $script:LastStep = $Message
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Find-Executable([string]$Name, [string[]]$FallbackPaths = @()) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($path in $FallbackPaths) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) { return $path }
    }
    return $null
}

function Ensure-WinGetPackage([string]$PackageId, [string]$ExecutableName, [string[]]$FallbackPaths = @()) {
    $found = Find-Executable $ExecutableName $FallbackPaths
    if ($found) { return $found }
    $wingetCommand = Get-Command 'winget.exe' -ErrorAction SilentlyContinue
    if (-not $wingetCommand) {
        throw "$ExecutableName no está instalado y tampoco se encuentra winget. Instala $PackageId desde Microsoft Store/winget y vuelve a ejecutar este script."
    }
    Write-Host "Instalando $PackageId con winget..." -ForegroundColor Yellow
    & $wingetCommand.Source install --id $PackageId --exact --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget no pudo instalar $PackageId (código $LASTEXITCODE). Instálalo y vuelve a ejecutar el script." }
    $found = Find-Executable $ExecutableName $FallbackPaths
    if (-not $found) { throw "$PackageId figura instalado, pero no se encontró $ExecutableName. Cierra y vuelve a abrir PowerShell." }
    return $found
}

function Invoke-Git([string[]]$Arguments, [switch]$AllowFailure) {
    $output = & $script:GitExe -C $Root @Arguments 2>&1
    $code = $LASTEXITCODE
    if ($code -ne 0 -and -not $AllowFailure) {
        throw "git $($Arguments -join ' ') falló (código $code): $($output -join [Environment]::NewLine)"
    }
    return [pscustomobject]@{ ExitCode=$code; Output=($output -join [Environment]::NewLine) }
}

function Invoke-Gh([string[]]$Arguments, [switch]$AllowFailure) {
    $output = & $script:GhExe @Arguments 2>&1
    $code = $LASTEXITCODE
    if ($code -ne 0 -and -not $AllowFailure) {
        throw "gh $($Arguments -join ' ') falló (código $code): $($output -join [Environment]::NewLine)"
    }
    return [pscustomobject]@{ ExitCode=$code; Output=($output -join [Environment]::NewLine) }
}

function Invoke-GhInteractive([string[]]$Arguments) {
    # Ejecuta gh con la consola adjunta: los códigos de un solo uso y las instrucciones del navegador permanecen visibles.
    & $script:GhExe @Arguments
    $interactiveCode = $LASTEXITCODE
    if ($interactiveCode -ne 0) {
        throw "gh $($Arguments -join ' ') falló (código $interactiveCode). Completa el flujo interactivo de GitHub y vuelve a ejecutar el script."
    }
}

function Test-GhHasScopes([string[]]$RequiredScopes) {
    # Devuelve $true solo si TODAS las cuentas listadas en gh auth status tienen los scopes requeridos.
    # Ante cualquier duda devuelve $false para que el script pida el reautorizado interactivo.
    $status = Invoke-Gh @('auth','status','--hostname','github.com') -AllowFailure
    if ($status.ExitCode -ne 0) { return $false }
    $scopeLines = @($status.Output -split '\r?\n' | Where-Object { $_ -match 'token scopes:' })
    if ($scopeLines.Count -eq 0) { return $false }
    foreach ($line in $scopeLines) {
        $scopes = @()
        foreach ($raw in (($line -replace '.*token scopes:\s*','') -split ',')) {
            $token = $raw.Trim().Trim("'").Trim('"').ToLowerInvariant()
            if ($token) { $scopes += $token }
        }
        foreach ($required in $RequiredScopes) {
            if (@($scopes | Where-Object { $_ -eq $required.ToLowerInvariant() }).Count -eq 0) { return $false }
        }
    }
    return $true
}

function ConvertFrom-GhTime([string]$Value) {
    # gh devuelve ISO-8601; analizarlo con cultura invariante evita fallos bajo calendarios no gregorianos.
    return ([DateTimeOffset]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)).UtcDateTime
}

function Get-WorkflowRuns([string]$Repository, [string]$Branch) {
    $result = Invoke-Gh @('run','list','--repo',$Repository,'--workflow',$WorkflowFile,'--branch',$Branch,'--limit','20','--json','databaseId,event,status,conclusion,url,headSha,createdAt') -AllowFailure
    if ($result.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($result.Output)) { return @() }
    try { return @($result.Output | ConvertFrom-Json) }
    catch { return @() }
}

try {
    Write-Step 'Revisando el paquete de origen'
    if (-not (Test-Path -LiteralPath $WorkflowPath -PathType Leaf)) { throw "No se encuentra el workflow: $WorkflowPath. Extrae el paquete completo antes de ejecutar." }
    if (-not (Test-Path -LiteralPath (Join-Path $Root 'tools\windows\Invoke-YorhaBuild.ps1') -PathType Leaf)) { throw 'Falta el compilador automático/validador del paquete; no se publicará un árbol incompleto.' }

    Write-Step 'Asegurando Git y GitHub CLI'
    $gitFallbackPaths = @()
    $ghFallbackPaths = @()
    foreach ($installRoot in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ([string]::IsNullOrWhiteSpace($installRoot)) { continue }
        $gitFallbackPaths += (Join-Path $installRoot 'Git\cmd\git.exe')
        $ghFallbackPaths += (Join-Path $installRoot 'GitHub CLI\gh.exe')
    }
    $script:GitExe = Ensure-WinGetPackage 'Git.Git' 'git.exe' $gitFallbackPaths
    $script:GhExe = Ensure-WinGetPackage 'GitHub.cli' 'gh.exe' $ghFallbackPaths

    Write-Step 'Comprobando autenticación y permisos necesarios'
    $auth = Invoke-Gh @('auth','status','--hostname','github.com') -AllowFailure
    if ($auth.ExitCode -ne 0) {
        Write-Host 'No se encontró sesión de GitHub CLI. Se abrirá la autenticación oficial: completa el código en el navegador.' -ForegroundColor Yellow
        Invoke-GhInteractive @('auth','login','--hostname','github.com','--git-protocol','https','--web')
    }
    # Solo volver a solicitar scopes si falta alguno (evita forzar un flujo de navegador cada ejecución).
    if (-not (Test-GhHasScopes @('repo','workflow'))) {
        Write-Host 'Se requieren los scopes repo y workflow. Se abrirá el navegador para reautorizar.' -ForegroundColor Yellow
        Invoke-GhInteractive @('auth','refresh','--hostname','github.com','--scopes','repo,workflow')
    }
    $null = Invoke-Gh @('auth','setup-git')
    $who = Invoke-Gh @('api','user','--jq','.login')
    $owner = $who.Output.Trim()
    if ([string]::IsNullOrWhiteSpace($owner)) { throw 'GitHub no devolvió un login autenticado.' }
    if (-not [string]::IsNullOrWhiteSpace($Owner)) { $owner = $Owner }
    $script:OwnerName = $owner
    $script:RepoFullName = "$owner/$RepositoryName"
    Write-Host "Cuenta autenticada: $owner"

    Write-Step 'Inicializando el árbol local sin sobrescribir historia remota'
    $gitDir = Join-Path $Root '.git'
    if (-not (Test-Path -LiteralPath $gitDir -PathType Container)) {
        $null = Invoke-Git @('init','--initial-branch=main')
    }
    $branchResult = Invoke-Git @('branch','--show-current')
    if ($branchResult.Output.Trim() -ne 'main') { $null = Invoke-Git @('branch','-M','main') }
    $userName = Invoke-Git @('config','user.name') -AllowFailure
    if ($userName.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($userName.Output)) {
        $null = Invoke-Git @('config','user.name',$owner)
    }
    $userEmail = Invoke-Git @('config','user.email') -AllowFailure
    if ($userEmail.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($userEmail.Output)) {
        # Use GitHub's noreply pattern instead of exposing a personal email in commits.
        $userId = (Invoke-Gh @('api','user','--jq','.id')).Output.Trim()
        $null = Invoke-Git @('config','user.email',"$userId+$owner@users.noreply.github.com")
    }
    $null = Invoke-Git @('add','-A')
    $staged = Invoke-Git @('status','--porcelain')
    if (-not [string]::IsNullOrWhiteSpace($staged.Output)) {
        $null = Invoke-Git @('commit','-m','Add Yorha Windows auto-build workflow V43')
    } else {
        $headCheck = Invoke-Git @('rev-parse','HEAD') -AllowFailure
        if ($headCheck.ExitCode -ne 0) { throw 'No existe un commit inicial y no hay archivos que confirmar.' }
    }
    $headSha = (Invoke-Git @('rev-parse','HEAD')).Output.Trim()

    Write-Step 'Creando o verificando el repositorio remoto'
    $remoteLookup = Invoke-Gh @('repo','view',$script:RepoFullName,'--json','nameWithOwner','--jq','.nameWithOwner') -AllowFailure
    if ($remoteLookup.ExitCode -ne 0) {
        $visibilityArgs = if ($Visibility -eq 'public') { @('--public') } else { @('--private') }
        $createArgs = @('repo','create',$script:RepoFullName) + $visibilityArgs + @('--description','Automated high-poly Yorha player model build and validation for Sven Co-op')
        $null = Invoke-Gh $createArgs
    } elseif ($remoteLookup.Output.Trim().ToLowerInvariant() -ne $script:RepoFullName.ToLowerInvariant()) {
        throw "GitHub resolvió un repositorio inesperado: $($remoteLookup.Output)"
    } else {
        $visibilityLookup = Invoke-Gh @('repo','view',$script:RepoFullName,'--json','visibility','--jq','.visibility') -AllowFailure
        if ($visibilityLookup.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($visibilityLookup.Output)) {
            throw "No se pudo verificar la visibilidad del repositorio existente $($script:RepoFullName). No se modificó el repositorio."
        }
        $script:ActualVisibility = $visibilityLookup.Output.Trim().ToLowerInvariant()
        if ($script:ActualVisibility -notin @('public','private','internal')) {
            throw "GitHub devolvió una visibilidad inesperada: $($visibilityLookup.Output)"
        }
    }
    Write-Host "Repositorio de destino: $($script:RepoFullName) (visibilidad actual: $($script:ActualVisibility))"

    $remote = Invoke-Git @('remote','get-url','origin') -AllowFailure
    $expectedUrl = "https://github.com/$($script:RepoFullName).git"
    if ($remote.ExitCode -eq 0) {
        if ($remote.Output.Trim().TrimEnd('/') -ne $expectedUrl.TrimEnd('/')) {
            throw "El remoto origin ya apunta a '$($remote.Output)'. No se modificó ni sobrescribió; usa una copia limpia del paquete para otro repo."
        }
    } else {
        $null = Invoke-Git @('remote','add','origin',$expectedUrl)
    }
    $expectedUrlNoGit = $expectedUrl.TrimEnd('.git')
    $startedUtc = [DateTime]::UtcNow
    $null = Invoke-Git @('push','--set-upstream','origin','main')
    Write-Host "Código publicado: $headSha" -ForegroundColor Green

    if ($SkipWorkflowWait) {
        $report = [ordered]@{ status='PUSHED_WORKFLOW_NOT_WAITED'; repository=$script:RepoFullName; branch='main'; commit=$headSha; pushed_utc=$startedUtc.ToString('o'); workflow="$expectedUrlNoGit/actions/workflows/$WorkflowFile" }
        $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $RunOutput 'DEPLOYMENT_STATUS.json') -Encoding UTF8
        Write-Host "Workflow publicado. Ejecuta: gh workflow run $WorkflowFile --repo $($script:RepoFullName) --ref main" -ForegroundColor Green
        exit 0
    }

    Write-Step 'Esperando la ejecución automática de GitHub Actions'
    $findDeadline = [DateTime]::UtcNow.AddSeconds(90)
    $run = $null
    while ([DateTime]::UtcNow -lt $findDeadline -and -not $run) {
        $runs = Get-WorkflowRuns $script:RepoFullName 'main'
        $run = $runs | Where-Object { $_.headSha -eq $headSha -and ((ConvertFrom-GhTime $_.createdAt) -ge $startedUtc.AddSeconds(-10)) } | Sort-Object { ConvertFrom-GhTime $_.createdAt } -Descending | Select-Object -First 1
        if (-not $run) { Start-Sleep -Seconds 10 }
    }
    if (-not $run) {
        Write-Host 'No apareció la ejecución por push; lanzando workflow_dispatch como respaldo.' -ForegroundColor Yellow
        $dispatchTime = [DateTime]::UtcNow
        $dispatch = Invoke-Gh @('workflow','run',$WorkflowFile,'--repo',$script:RepoFullName,'--ref','main') -AllowFailure
        if ($dispatch.ExitCode -ne 0) {
            Write-Host "No se pudo lanzar workflow_dispatch como respaldo: $($dispatch.Output)" -ForegroundColor Yellow
        } else {
            $dispatchDeadline = [DateTime]::UtcNow.AddSeconds(90)
            while ([DateTime]::UtcNow -lt $dispatchDeadline -and -not $run) {
                $runs = Get-WorkflowRuns $script:RepoFullName 'main'
                $run = $runs | Where-Object { $_.headSha -eq $headSha -and $_.event -eq 'workflow_dispatch' -and ((ConvertFrom-GhTime $_.createdAt) -ge $dispatchTime.AddSeconds(-10)) } | Sort-Object { ConvertFrom-GhTime $_.createdAt } -Descending | Select-Object -First 1
                if (-not $run) { Start-Sleep -Seconds 10 }
            }
        }
    }
    if (-not $run) { throw 'El push terminó, pero GitHub no devolvió una ejecución para este commit. Revisa la pestaña Actions y el archivo .github/workflows/yorha-windows-auto-build.yml.' }
    $script:RunId = [string]$run.databaseId
    $runUrl = [string]$run.url
    if ([string]::IsNullOrWhiteSpace($runUrl)) { $runUrl = "https://github.com/$($script:RepoFullName)/actions/runs/$($script:RunId)" }
    Write-Host "Ejecución: $runUrl" -ForegroundColor Green

    $runDeadline = [DateTime]::UtcNow.AddMinutes($WaitMinutes)
    $finalRun = $null
    while ([DateTime]::UtcNow -lt $runDeadline) {
        $view = Invoke-Gh @('run','view',$script:RunId,'--repo',$script:RepoFullName,'--json','databaseId,status,conclusion,url,headSha,event,createdAt') -AllowFailure
        if ($view.ExitCode -eq 0) {
            try { $finalRun = $view.Output | ConvertFrom-Json } catch { $finalRun = $null }
        }
        if ($finalRun -and $finalRun.status -eq 'completed') { break }
        if ($finalRun) { Write-Host "Estado del runner: $($finalRun.status)"; }
        Start-Sleep -Seconds 15
    }
    if (-not $finalRun -or $finalRun.status -ne 'completed') {
        $timeoutReport = [ordered]@{ status='RUN_STILL_IN_PROGRESS_OR_STATUS_UNAVAILABLE'; repository=$script:RepoFullName; commit=$headSha; run_id=$script:RunId; run_url=$runUrl; checked_utc=[DateTime]::UtcNow.ToString('o'); wait_minutes=$WaitMinutes }
        $timeoutReport | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $RunOutput 'DEPLOYMENT_STATUS.json') -Encoding UTF8
        throw "La ejecución no terminó dentro de $WaitMinutes minutos. No se declara compilación aprobada; revisa $runUrl."
    }

    Write-Step 'Descargando artefactos, MDL y evidencia de compilación'
    $artifactDir = Join-Path $RunOutput "run-$($script:RunId)"
    $null = New-Item -ItemType Directory -Path $artifactDir -Force
    $download = Invoke-Gh @('run','download',$script:RunId,'--repo',$script:RepoFullName,'--dir',$artifactDir) -AllowFailure
    $download | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $artifactDir 'DOWNLOAD_RESULT.json') -Encoding UTF8
    $failureLogPath = Join-Path $artifactDir 'github-actions-failed.log'
    if ($finalRun.conclusion -ne 'success') {
        $failedLog = Invoke-Gh @('run','view',$script:RunId,'--repo',$script:RepoFullName,'--log-failed') -AllowFailure
        $failedLog.Output | Set-Content -LiteralPath $failureLogPath -Encoding UTF8
    }
    $mdlFiles = @(Get-ChildItem -LiteralPath $artifactDir -Filter 'yorha.mdl' -File -Recurse -ErrorAction SilentlyContinue)
    $buildReports = @(Get-ChildItem -LiteralPath $artifactDir -Filter 'YORHA_AUTO_BUILD_REPORT.json' -File -Recurse -ErrorAction SilentlyContinue)
    $mdlReports = @(Get-ChildItem -LiteralPath $artifactDir -Filter 'yorha-mdl-structural-validation.json' -File -Recurse -ErrorAction SilentlyContinue)
    $buildStatus = if ($finalRun.conclusion -eq 'success' -and $mdlFiles.Count -ge 1 -and $buildReports.Count -ge 1 -and $mdlReports.Count -ge 1) { 'PASS_COMPILE_ARTIFACT_AND_STRUCTURAL_REPORT_DOWNLOADED' } elseif ($finalRun.conclusion -eq 'success') { 'CI_SUCCESS_BUT_REQUIRED_MDL_EVIDENCE_MISSING' } else { 'WORKFLOW_FAILED_REVIEW_DOWNLOADED_LOGS' }
    $report = [ordered]@{
        status=$buildStatus
        owner=$script:OwnerName
        repository=$script:RepoFullName
        visibility=$script:ActualVisibility
        branch='main'
        commit=$headSha
        run_id=$script:RunId
        run_url=$runUrl
        event=$finalRun.event
        conclusion=$finalRun.conclusion
        completed_utc=[DateTime]::UtcNow.ToString('o')
        artifacts_directory=$artifactDir
        mdl_artifacts=@($mdlFiles | ForEach-Object { [ordered]@{ path=$_.FullName; bytes=$_.Length; sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() } })
        build_report_count=$buildReports.Count
        mdl_structural_report_count=$mdlReports.Count
        runtime_test='PENDING_HLMV_SVEN_COOP_IN_GAME'
    }
    $report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $RunOutput 'DEPLOYMENT_STATUS.json') -Encoding UTF8
    Write-Host "Estado final: $buildStatus" -ForegroundColor $(if ($buildStatus -like 'PASS_*') { 'Green' } else { 'Yellow' })
    Write-Host "Repositorio: https://github.com/$($script:RepoFullName)"
    Write-Host "Acciones: $runUrl"
    Write-Host "Informes y artefactos: $artifactDir"

    if ($buildStatus -ne 'PASS_COMPILE_ARTIFACT_AND_STRUCTURAL_REPORT_DOWNLOADED') {
        if ($finalRun.conclusion -eq 'success') { throw 'GitHub informó éxito, pero faltan el MDL o sus informes binarios obligatorios. Se registra como fallo de evidencia, no como compilación validada.' }
        throw "GitHub Actions terminó con conclusión '$($finalRun.conclusion)'. El log de fallo y los artefactos disponibles se guardaron en $artifactDir."
    }
    exit 0
} catch {
    $errorText = $_.Exception.Message
    Write-Host "`nERROR en paso '$script:LastStep': $errorText" -ForegroundColor Red
    $failureReport = [ordered]@{
        status='DEPLOYMENT_OR_WORKFLOW_FAILURE'
        step=$script:LastStep
        owner=$script:OwnerName
        repository=$script:RepoFullName
        run_id=$script:RunId
        error=$errorText
        timestamp_utc=[DateTime]::UtcNow.ToString('o')
        guidance='Conserva build/github-actions/ y comparte DEPLOYMENT_STATUS.json, los logs de fallo y los informes. Nunca se declara válido un MDL sin el artefacto y el informe estructural.'
    }
    try { $failureReport | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $RunOutput 'DEPLOYMENT_FAILURE.json') -Encoding UTF8 } catch {}
    exit 1
}
