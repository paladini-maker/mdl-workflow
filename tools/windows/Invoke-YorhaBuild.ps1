[CmdletBinding()]
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string]$CompilerPath,
    [switch]$UseProvidedCompiler,
    [switch]$ForceCompilerUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$OfficialToolUrl = 'https://gamebanana.com/tools/6552'
$OfficialApiUrls = @(
    'https://api.gamebanana.com/Core/Item/Data?itemtype=Tool&itemid=6552&fields=Files%28%29.aFiles%28%29&format=json',
    'https://api.gamebanana.com/Core/Item/Data?itemtype=Tools&itemid=6552&fields=Files%28%29.aFiles%28%29&format=json',
    'https://gamebanana.com/tools/6552?api=ProfilePage'
)
$ExpectedArchiveName = 'funnkyhd-studiomdl_f6dee.7z'
$script:ResolvedGameBananaApiUrl = $null
$script:DownloadedCompilerInfo = $null
$Root = (Resolve-Path -LiteralPath $Root).Path
$Validator = Join-Path $Root 'tools\windows\validate_yorha_auto_workflow.py'
$ProbeSource = Join-Path $Root 'tools\windows\compiler_probe'
$CompilerCache = Join-Path $Root 'tools\FunnkyHD_StudioMDL_V2.0'
$CompilerArchive = Join-Path $CompilerCache $ExpectedArchiveName
$CompilerMetadata = Join-Path $CompilerCache 'compiler-info.json'
$WorkRoot = Join-Path $Root 'build\windows_auto'
$LogRoot = Join-Path $WorkRoot 'logs'
$ReportRoot = Join-Path $WorkRoot 'reports'
$StagingRoot = Join-Path $WorkRoot 'staging'
$TargetMdl = Join-Path $Root 'models\player\yorha\yorha.mdl'

foreach ($dir in @($CompilerCache, $WorkRoot, $LogRoot, $ReportRoot, $StagingRoot, (Split-Path -Parent $TargetMdl))) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

function Write-Step([string]$Message) {
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Get-PythonCommand {
    $py = Get-Command 'py.exe' -ErrorAction SilentlyContinue
    if ($py) {
        $probe = & $py.Source -3 --version 2>&1
        if ($LASTEXITCODE -eq 0) { return [pscustomobject]@{ File=$py.Source; Prefix=@('-3') } }
    }
    $python = Get-Command 'python.exe' -ErrorAction SilentlyContinue
    if ($python) {
        $probe = & $python.Source --version 2>&1
        if ($LASTEXITCODE -eq 0) { return [pscustomobject]@{ File=$python.Source; Prefix=@() } }
    }
    throw 'Python 3 no está disponible. Instala Python 3.10+ y vuelve a ejecutar; el validador solo usa la biblioteca estándar.'
}

$PythonCommand = $null

function Get-FileCandidateFromApi($Node, [string]$ParentKey = '') {
    # GameBanana API versions have returned either a numeric-keyed file map or
    # arrays of file records. Descend into nested records before accepting a
    # parent item's ID; otherwise the tool's ID (6552) could be mistaken for
    # the downloadable file ID.
    if ($null -eq $Node) { return $null }
    if ($Node -is [string]) {
        if ($Node -match '(?i)^funnkyhd-studiomdl_f6dee\.7z$' -and $ParentKey -match '^\d{4,}$') {
            return [pscustomobject]@{ Id=$ParentKey; Name=$Node }
        }
        return $null
    }
    if ($Node -is [System.Collections.IDictionary]) {
        $props = @($Node.GetEnumerator())
        foreach ($entry in $props) {
            if ([string]$entry.Key -match '^\d{4,}$' -and (ConvertTo-Json -InputObject $entry.Value -Depth 30 -Compress) -match '(?i)funnkyhd-studiomdl_f6dee\.7z') {
                return [pscustomobject]@{ Id=[string]$entry.Key; Name=$ExpectedArchiveName }
            }
        }
        $directName = $false
        foreach ($entry in $props) {
            if ([string]$entry.Key -match '(?i)^_?s?(?:file|filename|name)$' -and [string]$entry.Value -match '(?i)^funnkyhd-studiomdl_f6dee\.7z$') { $directName = $true; break }
        }
        if ($directName) {
            foreach ($entry in $props) {
                if ([string]$entry.Key -match '(?i)^(?:_?id(?:row|file)?|i?fileid|rowid)$' -and [string]$entry.Value -match '^\d{4,}$') {
                    return [pscustomobject]@{ Id=[string]$entry.Value; Name=$ExpectedArchiveName }
                }
            }
        }
        foreach ($entry in $props) {
            $found = Get-FileCandidateFromApi $entry.Value ([string]$entry.Key)
            if ($found) { return $found }
        }
        if ($ParentKey -match '^\d{4,}$' -and (ConvertTo-Json -InputObject $Node -Depth 30 -Compress) -match '(?i)funnkyhd-studiomdl_f6dee\.7z') {
            return [pscustomobject]@{ Id=$ParentKey; Name=$ExpectedArchiveName }
        }
        return $null
    }
    if ($Node -is [System.Management.Automation.PSCustomObject]) {
        $props = @($Node.PSObject.Properties)
        foreach ($prop in $props) {
            if ($prop.Name -match '^\d{4,}$' -and (ConvertTo-Json -InputObject $prop.Value -Depth 30 -Compress) -match '(?i)funnkyhd-studiomdl_f6dee\.7z') {
                return [pscustomobject]@{ Id=$prop.Name; Name=$ExpectedArchiveName }
            }
        }
        $directName = $false
        foreach ($prop in $props) {
            if ($prop.Name -match '(?i)^_?s?(?:file|filename|name)$' -and [string]$prop.Value -match '(?i)^funnkyhd-studiomdl_f6dee\.7z$') { $directName = $true; break }
        }
        if ($directName) {
            foreach ($prop in $props) {
                if ($prop.Name -match '(?i)^(?:_?id(?:row|file)?|i?fileid|rowid)$' -and [string]$prop.Value -match '^\d{4,}$') {
                    return [pscustomobject]@{ Id=[string]$prop.Value; Name=$ExpectedArchiveName }
                }
            }
        }
        foreach ($prop in $props) {
            $found = Get-FileCandidateFromApi $prop.Value $prop.Name
            if ($found) { return $found }
        }
        if ($ParentKey -match '^\d{4,}$' -and (ConvertTo-Json -InputObject $Node -Depth 30 -Compress) -match '(?i)funnkyhd-studiomdl_f6dee\.7z') {
            return [pscustomobject]@{ Id=$ParentKey; Name=$ExpectedArchiveName }
        }
        return $null
    }
    if ($Node -is [System.Collections.IEnumerable]) {
        $array = @($Node)
        for ($i=0; $i -lt $array.Count; $i++) {
            $found = Get-FileCandidateFromApi $array[$i] $ParentKey
            if ($found) { return $found }
            if ($array[$i] -is [string] -and $array[$i] -match '(?i)^funnkyhd-studiomdl_f6dee\.7z$' -and $i -gt 0 -and [string]$array[$i-1] -match '^\d{4,}$') {
                return [pscustomobject]@{ Id=[string]$array[$i-1]; Name=$array[$i] }
            }
        }
    }
    return $null
}

function Get-Portable7zr {
    # Self-bootstrap a small extractor from the official 7-Zip site when the user
    # has neither 7-Zip nor an archive-capable tar.exe. The EXE is never bundled.
    $portable = Join-Path $CompilerCache '7zr.exe'
    $extractorInfoPath = Join-Path $CompilerCache '7zr-info.json'
    if (Test-Path -LiteralPath $portable) {
        try {
            $existing = [System.IO.File]::ReadAllBytes($portable)
            $extractorInfo = Get-Content -LiteralPath $extractorInfoPath -Raw | ConvertFrom-Json
            $actualHash = (Get-FileHash -LiteralPath $portable -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($existing.Length -ge 100000 -and $existing.Length -le 20000000 -and $existing[0] -eq 0x4D -and $existing[1] -eq 0x5A -and $actualHash -eq [string]$extractorInfo.sha256) {
                return $portable
            }
        } catch { }
        # A missing/malformed metadata record or a changed binary invalidates this cache.
        Remove-Item -LiteralPath $portable -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $extractorInfoPath -Force -ErrorAction SilentlyContinue
    }
    $sourceUrl = 'https://www.7-zip.org/a/7zr.exe'
    $temp = "$portable.download"
    Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    Write-Step 'Descargando extractor 7zr desde el sitio oficial de 7-Zip'
    try {
        Invoke-WebRequest -Uri $sourceUrl -UseBasicParsing -OutFile $temp -Headers @{ 'User-Agent'='Yorha-SvEngine-AutoBuild/41' } -TimeoutSec 120
        $bytes = [System.IO.File]::ReadAllBytes($temp)
        if ($bytes.Length -lt 100000 -or $bytes.Length -gt 20000000 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
            throw 'El descargable de 7-Zip no parece un ejecutable PE válido.'
        }
        Move-Item -LiteralPath $temp -Destination $portable -Force
        $extractorInfo = [ordered]@{
            status='PASS_OFFICIAL_7ZIP_PORTABLE_EXTRACTOR'
            source_url=$sourceUrl
            downloaded_at_utc=[DateTime]::UtcNow.ToString('o')
            bytes=(Get-Item -LiteralPath $portable).Length
            sha256=(Get-FileHash -LiteralPath $portable -Algorithm SHA256).Hash.ToLowerInvariant()
        }
        $extractorInfo | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $CompilerCache '7zr-info.json') -Encoding UTF8
        return $portable
    } catch {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        throw "No pude preparar el extractor desde el sitio oficial de 7-Zip ($sourceUrl). Instala 7-Zip y vuelve a ejecutar. Detalle: $($_.Exception.Message)"
    }
}

function Expand-7ZipArchive([string]$ArchivePath, [string]$Destination) {
    $sevenZipCandidates = @( @(
        (Get-Command '7z.exe' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        "$env:ProgramFiles\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } )
    $extractor = $null
    if ($sevenZipCandidates.Count -gt 0) {
        $extractor = $sevenZipCandidates[0]
    } else {
        $extractor = Get-Portable7zr
    }
    # Always test archive integrity before extraction. A successful listing alone is insufficient.
    & $extractor 't' $ArchivePath '-y'
    if ($LASTEXITCODE -ne 0) { throw "7-Zip no superó la prueba de integridad del archivo: $ArchivePath" }
    & $extractor 'x' $ArchivePath ("-o" + $Destination) '-y'
    if ($LASTEXITCODE -ne 0) { throw "7-Zip no pudo extraer el archivo: $ArchivePath" }
}

function Download-OfficialFunnkyHDV2 {
    Write-Step 'Descargando FunnkyHD StudioMDL V2.0 desde GameBanana oficial'
    $oldTls = [System.Net.ServicePointManager]::SecurityProtocol
    try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 } catch { }
    $candidate = $null
    $apiErrors = [System.Collections.Generic.List[string]]::new()
    foreach ($apiUrl in $OfficialApiUrls) {
        try {
            $apiResponse = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing -Headers @{ 'User-Agent'='Yorha-SvEngine-AutoBuild/41'; 'Accept'='application/json' } -TimeoutSec 45
            $apiJson = $apiResponse.Content | ConvertFrom-Json
            $candidate = Get-FileCandidateFromApi $apiJson ''
            if ($candidate -and $candidate.Id -match '^\d{4,}$') { $script:ResolvedGameBananaApiUrl = $apiUrl; break }
            $apiErrors.Add("No se encontró el archivo principal V2.0 en: $apiUrl")
        } catch { $apiErrors.Add("$apiUrl => $($_.Exception.Message)") }
    }
    if (-not $candidate -or $candidate.Id -notmatch '^\d{4,}$') {
        throw "No se pudo identificar automáticamente el archivo '$ExpectedArchiveName' en la API de GameBanana. Descárgalo desde $OfficialToolUrl y ejecuta con -UseProvidedCompiler -CompilerPath <ruta>; el script verificará que splitmesh funcione. Detalles: $($apiErrors -join ' | ')"
    }
    $downloadUrl = "https://gamebanana.com/dl/$($candidate.Id)"
    $downloadTemp = "$CompilerArchive.download"
    Remove-Item -LiteralPath $downloadTemp -Force -ErrorAction SilentlyContinue
    try {
        Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing -OutFile $downloadTemp -Headers @{ 'User-Agent'='Yorha-SvEngine-AutoBuild/41' } -TimeoutSec 180
    } catch {
        throw "No pude descargar '$ExpectedArchiveName' desde $downloadUrl. Descarga el archivo principal de $OfficialToolUrl e inténtalo con -CompilerPath. Detalle: $($_.Exception.Message)"
    }
    $bytes = [System.IO.File]::ReadAllBytes($downloadTemp)
    if ($bytes.Length -lt 32 -or $bytes[0] -ne 0x37 -or $bytes[1] -ne 0x7A -or $bytes[2] -ne 0xBC -or $bytes[3] -ne 0xAF) {
        Remove-Item -LiteralPath $downloadTemp -Force -ErrorAction SilentlyContinue
        throw "La descarga no tiene cabecera 7z válida; posiblemente GameBanana entregó una página de aviso en vez del archivo. Descárgalo manualmente desde $OfficialToolUrl."
    }
    Move-Item -LiteralPath $downloadTemp -Destination $CompilerArchive -Force
    $archiveHash = (Get-FileHash -LiteralPath $CompilerArchive -Algorithm SHA256).Hash.ToLowerInvariant()
    $extract = Join-Path $CompilerCache 'distribution'
    if (Test-Path -LiteralPath $extract) { Remove-Item -LiteralPath $extract -Recurse -Force }
    New-Item -ItemType Directory -Path $extract -Force | Out-Null
    Expand-7ZipArchive -ArchivePath $CompilerArchive -Destination $extract
    $exe = Get-ChildItem -LiteralPath $extract -Filter 'studiomdl.exe' -File -Recurse | Select-Object -First 1
    if (-not $exe) { throw "El archivo V2.0 se extrajo, pero no contiene studiomdl.exe. Archivo: $CompilerArchive" }
    $exeHash = (Get-FileHash -LiteralPath $exe.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $info = [ordered]@{
        status='DOWNLOADED_OFFICIAL_V2_CANDIDATE'
        product='FunnkyHD StudioMDL'
        version='2.0'
        source_url=$OfficialToolUrl
        api_url=$script:ResolvedGameBananaApiUrl
        capabilities=[ordered]@{ splitmesh=$true; max_vertices_per_piece=2048; max_normals_per_piece=2048; default_max_triangles_per_piece=4080; maximum_bodyparts=64; sven_max_texture_dimension=1024 }
        download_url=$downloadUrl
        source_file=$ExpectedArchiveName
        source_file_id=[string]$candidate.Id
        archive_sha256=$archiveHash
        executable_relative_path=$exe.FullName.Substring($Root.Length).TrimStart('\')
        executable_sha256=$exeHash
        downloaded_at_utc=[DateTime]::UtcNow.ToString('o')
        compiler_capability_probe='PENDING'
    }
    $script:DownloadedCompilerInfo = $info
    return $exe.FullName
}

function Test-SplitMeshCompiler([string]$ExePath, [string]$Label) {
    Write-Step "Comprobando ${Label}: ${ExePath}"
    $probeDir = Join-Path $StagingRoot ("compiler_probe_" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
    Get-ChildItem -LiteralPath $ProbeSource -File | Copy-Item -Destination $probeDir -Force
    $stdout = Join-Path $probeDir 'studiomdl.stdout.log'
    $stderr = Join-Path $probeDir 'studiomdl.stderr.log'
    $proc = Start-Process -FilePath $ExePath -ArgumentList 'probe.qc' -WorkingDirectory $probeDir -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $combined = ''
    foreach ($log in @($stdout,$stderr)) { if (Test-Path -LiteralPath $log) { $combined += [System.IO.File]::ReadAllText($log) + "`n" } }
    if ($combined -match '(?i)bad command\s+\"?\$splitmesh|unknown command\s+\$splitmesh|unrecognized.*splitmesh') {
        throw "El compilador no reconoce `$splitmesh; no se acepta una salida parcial. Log: $probeDir"
    }
    $mdl = Join-Path $probeDir 'compiler_probe.mdl'
    if ($proc.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $mdl)) {
        throw "El compilador no superó la prueba de QC/SMD/BMP. ExitCode=$($proc.ExitCode). Log: $probeDir"
    }
    $report = Join-Path $probeDir 'splitmesh_probe.validation.json'
    $pythonArgs = @(); $pythonArgs += $PythonCommand.Prefix; $pythonArgs += @($Validator,'--root',$Root,'--mode','probe','--mdl',$mdl,'--report',$report)
    & $PythonCommand.File @pythonArgs | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "El compilador generó un MDL, pero no pasó la prueba de división efectiva (2050 triángulos, >2048 vértices). Log: $probeDir" }
    $json = Get-Content -LiteralPath $report -Raw | ConvertFrom-Json
    if ($json.bodyparts -lt 2 -or $json.bodyparts -gt 64 -or $json.triangles_total -ne 2050) {
        throw "Prueba `$splitmesh inesperada: bodyparts=$($json.bodyparts), triangles=$($json.triangles_total). Log: $probeDir"
    }
    Write-Host "PASS: $Label divide una malla de 2050 triángulos en $($json.bodyparts) bodyparts; los vértices/normales por parte cumplen el límite 2048." -ForegroundColor Green
    return [pscustomobject]@{ Path=$ExePath; ProbeDirectory=$probeDir; Report=$report; BodyParts=$json.bodyparts; MdlSha256=$json.sha256; Label=$Label }
}

function Get-TrustedCompiler {
    $candidatePath = $null
    $cacheValid = $false
    if (-not $ForceCompilerUpdate -and (Test-Path -LiteralPath $CompilerMetadata)) {
        try {
            $info = Get-Content -LiteralPath $CompilerMetadata -Raw | ConvertFrom-Json
            $candidatePath = Join-Path $Root ([string]$info.executable_relative_path)
            if ($info.version -eq '2.0' -and $info.status -eq 'PASS_OFFICIAL_V2_0_DOWNLOADED_AND_CAPABILITY_TESTED' -and $info.compiler_capability_probe -eq 'PASS_SPLITMESH_2050_TRIANGLE_FIXTURE' -and (Test-Path -LiteralPath $candidatePath)) {
                $actual = (Get-FileHash -LiteralPath $candidatePath -Algorithm SHA256).Hash.ToLowerInvariant()
                $cacheValid = $actual -eq [string]$info.executable_sha256
            }
        } catch { $cacheValid = $false }
    }
    if ($cacheValid) {
        try {
            $test = Test-SplitMeshCompiler $candidatePath 'FunnkyHD StudioMDL V2.0 (caché SHA-256 verificada)'
            return $test
        } catch {
            Write-Warning "La caché V2.0 no pasó el probe; se descargará una copia nueva. $($_.Exception.Message)"
            $cacheValid = $false
        }
    }
    if ($UseProvidedCompiler) {
        if (-not $CompilerPath) { $CompilerPath = $env:STUDIOMDL }
        if (-not $CompilerPath -or -not (Test-Path -LiteralPath $CompilerPath)) { throw '-UseProvidedCompiler requiere -CompilerPath o STUDIOMDL válido.' }
        $provided = Test-SplitMeshCompiler (Resolve-Path -LiteralPath $CompilerPath).Path 'Compilador especificado por el usuario (solo si supera el probe)'
        return $provided
    }
    if ($ForceCompilerUpdate -or -not $cacheValid) {
        # Delete old executable metadata before downloading so a failed update cannot masquerade as V2.0.
        Remove-Item -LiteralPath $CompilerMetadata -Force -ErrorAction SilentlyContinue
        $exe = Download-OfficialFunnkyHDV2
        $probe = Test-SplitMeshCompiler $exe 'FunnkyHD StudioMDL V2.0 recién descargado del origen oficial'
        $script:DownloadedCompilerInfo.compiler_capability_probe = 'PASS_SPLITMESH_2050_TRIANGLE_FIXTURE'
        $script:DownloadedCompilerInfo.probe_bodyparts = $probe.BodyParts
        $script:DownloadedCompilerInfo.probe_mdl_sha256 = $probe.MdlSha256
        $script:DownloadedCompilerInfo.status = 'PASS_OFFICIAL_V2_0_DOWNLOADED_AND_CAPABILITY_TESTED'
        $metaPath = Join-Path $CompilerCache 'compiler-info.json'
        $script:DownloadedCompilerInfo | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $metaPath -Encoding UTF8
        return $probe
    }
    throw 'No se pudo seleccionar un compilador compatible.'
}

function Invoke-CompileAndValidate([string]$ExePath, [string]$CompilerLabel) {
    Write-Step 'Validando los archivos fuente'
    $sourceReport = Join-Path $ReportRoot 'source-preflight.json'
    $pythonArgs = @(); $pythonArgs += $PythonCommand.Prefix; $pythonArgs += @($Validator,'--root',$Root,'--mode','sources','--report',$sourceReport)
    & $PythonCommand.File @pythonArgs | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Preflight de assets falló; StudioMDL no se ejecutó. Informe: $sourceReport" }

    # Preserve the last valid MDL and sidecar groups. The output is restored on any failure.
    $modelDir = Split-Path -Parent $TargetMdl
    $backupDir = Join-Path $StagingRoot ("previous_output_" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $previous = @(Get-ChildItem -LiteralPath $modelDir -Filter 'yorha*.mdl' -File -ErrorAction SilentlyContinue)
    foreach ($file in $previous) { Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $backupDir $file.Name) -Force }
    $previousSums = Join-Path $modelDir 'SHA256SUMS.txt'
    if (Test-Path -LiteralPath $previousSums) { Copy-Item -LiteralPath $previousSums -Destination (Join-Path $backupDir 'SHA256SUMS.txt') -Force }
    $reportPath = Join-Path $ReportRoot 'YORHA_AUTO_BUILD_REPORT.json'
    if (Test-Path -LiteralPath $reportPath) { Copy-Item -LiteralPath $reportPath -Destination (Join-Path $backupDir 'YORHA_AUTO_BUILD_REPORT.json') -Force }
    $buildLog = Join-Path $LogRoot 'studiomdl_yorha.log'
    $stdout = Join-Path $LogRoot 'studiomdl_yorha.stdout.log'
    $stderr = Join-Path $LogRoot 'studiomdl_yorha.stderr.log'
    try {
        Remove-Item -LiteralPath $TargetMdl -Force -ErrorAction SilentlyContinue
        foreach ($file in $previous) { Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue }
        $proc = Start-Process -FilePath $ExePath -ArgumentList 'custom_player_windows.qc' -WorkingDirectory $Root -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $allLogs = ''
        foreach ($log in @($stdout,$stderr)) { if (Test-Path -LiteralPath $log) { $allLogs += [System.IO.File]::ReadAllText($log) + "`n" } }
        Set-Content -LiteralPath $buildLog -Value $allLogs -Encoding UTF8
        if ($allLogs -match '(?i)bad command\s+\"?\$(?:splitmesh|resizetexture)') {
            throw 'StudioMDL reportó una directiva QC desconocida; se rechaza la compilación aunque haya creado un MDL parcial.'
        }
        if ($proc.ExitCode -ne 0) { throw "StudioMDL terminó con ExitCode=$($proc.ExitCode). Log: $buildLog" }
        if (-not (Test-Path -LiteralPath $TargetMdl)) { throw "StudioMDL devolvió éxito, pero no creó el modelo esperado: $TargetMdl" }
        Write-Step 'Validando el MDL binario recién compilado'
        $mdlReport = Join-Path $ReportRoot 'yorha-mdl-structural-validation.json'
        $pythonArgs = @(); $pythonArgs += $PythonCommand.Prefix; $pythonArgs += @($Validator,'--root',$Root,'--mode','mdl','--mdl',$TargetMdl,'--report',$mdlReport)
        & $PythonCommand.File @pythonArgs | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "El MDL no pasó la validación binaria; se restaurará la salida anterior. Informe: $mdlReport" }
        $mdlJson = Get-Content -LiteralPath $mdlReport -Raw | ConvertFrom-Json
        if ($mdlJson.bodyparts -gt 64) { throw "El MDL excede 64 bodyparts: $($mdlJson.bodyparts)" }
        if ($mdlJson.triangles_total -ne 99998) { throw "El MDL no conservó todos los triángulos: $($mdlJson.triangles_total)" }
        $groups = Get-ChildItem -LiteralPath $modelDir -Filter 'yorha*.mdl' -File
        $hashLines = foreach ($file in $groups) { $h=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant(); "$h  $($file.Name)" }
        Set-Content -LiteralPath (Join-Path $modelDir 'SHA256SUMS.txt') -Value $hashLines -Encoding ASCII
        $buildReport = [ordered]@{
            status='PASS_COMPILED_AND_STRUCTURALLY_VALIDATED'
            compiler=$CompilerLabel
            compiler_path=$ExePath
            compiler_sha256=(Get-FileHash -LiteralPath $ExePath -Algorithm SHA256).Hash.ToLowerInvariant()
            finished_utc=[DateTime]::UtcNow.ToString('o')
            source_report=$sourceReport
            mdl_report=$mdlReport
            compiler_log=$buildLog
            main_mdl=$TargetMdl
            model_sha256=$mdlJson.sha256
            bones=$mdlJson.bones
            sequences=$mdlJson.sequences
            bodyparts=$mdlJson.bodyparts
            triangles=$mdlJson.triangles_total
            max_vertices_per_piece=$mdlJson.max_vertices_per_piece
            max_normals_per_piece=$mdlJson.max_normals_per_piece
            texture=$mdlJson.textures
            sequence_groups=$mdlJson.sequence_groups
            external_runtime_test='PENDING_HLMV_SVEN_COOP'
        }
        $buildReport | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $reportPath -Encoding UTF8
        # Optional safe user-addon copy; never overwrite the game's base svencoop directory by default.
        if ($env:SVENCOOP_ADDON_DIR) {
            $addonModelDir = Join-Path $env:SVENCOOP_ADDON_DIR 'models\player\yorha'
            New-Item -ItemType Directory -Path $addonModelDir -Force | Out-Null
            foreach ($file in $groups) { Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $addonModelDir $file.Name) -Force }
            $addonHash = (Get-FileHash -LiteralPath (Join-Path $addonModelDir 'yorha.mdl') -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($addonHash -ne $mdlJson.sha256) { throw 'El MDL copiado a svencoop_addon no coincide con el hash de salida.' }
            $buildReport['addon_copy'] = $addonModelDir
            $buildReport | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $reportPath -Encoding UTF8
            Write-Host "PASS: copia verificada en $addonModelDir" -ForegroundColor Green
        }
        Write-Host "`nBUILD PASS: $TargetMdl" -ForegroundColor Green
        Write-Host "Hash: $($mdlJson.sha256)" -ForegroundColor Green
        Write-Host "Informe: $reportPath" -ForegroundColor Green
        return $buildReport
    } catch {
        # Restore the previous verified model on any compile or binary-validation failure.
        Get-ChildItem -LiteralPath $modelDir -Filter 'yorha*.mdl' -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        foreach ($old in Get-ChildItem -LiteralPath $backupDir -Filter 'yorha*.mdl' -File -ErrorAction SilentlyContinue) {
            Copy-Item -LiteralPath $old.FullName -Destination (Join-Path $modelDir $old.Name) -Force
        }
        $oldSums = Join-Path $backupDir 'SHA256SUMS.txt'
        if (Test-Path -LiteralPath $oldSums) { Copy-Item -LiteralPath $oldSums -Destination (Join-Path $modelDir 'SHA256SUMS.txt') -Force }
        else { Remove-Item -LiteralPath (Join-Path $modelDir 'SHA256SUMS.txt') -Force -ErrorAction SilentlyContinue }
        $oldReport = Join-Path $backupDir 'YORHA_AUTO_BUILD_REPORT.json'
        if (Test-Path -LiteralPath $oldReport) { Copy-Item -LiteralPath $oldReport -Destination $reportPath -Force }
        else { Remove-Item -LiteralPath $reportPath -Force -ErrorAction SilentlyContinue }
        throw
    }
}

try {
    $PythonCommand = Get-PythonCommand
    Remove-Item -LiteralPath (Join-Path $ReportRoot 'YORHA_AUTO_BUILD_FAILURE_REPORT.json') -Force -ErrorAction SilentlyContinue
    Write-Step 'Yorha automatic build V42 — fail-closed'
    Write-Host "Project: $Root"
    Write-Host 'Policy: only use official FunnkyHD StudioMDL V2.0 by default; it is selected for high-poly splitting, not unlimited engine limits; do not continue with old compilers that reject $splitmesh.'
    Write-Step 'Ejecutando pruebas de regresión del workflow/validador'
    $testScript = Join-Path $Root 'tools\windows\test_yorha_auto_workflow.py'
    $testArgs = @(); $testArgs += $PythonCommand.Prefix; $testArgs += @($testScript)
    & $PythonCommand.File @testArgs | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'Las pruebas de regresión del workflow fallaron; no se seleccionará compilador ni se escribirá el MDL final.' }
    $preflightReport = Join-Path $ReportRoot 'source-preflight-before-compiler.json'
    $pythonArgs = @(); $pythonArgs += $PythonCommand.Prefix; $pythonArgs += @($Validator,'--root',$Root,'--mode','sources','--report',$preflightReport)
    & $PythonCommand.File @pythonArgs | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Source validation failed. No compiler was run. See $preflightReport" }

    if ($UseProvidedCompiler) {
        if (-not $CompilerPath) { $CompilerPath = $env:STUDIOMDL }
        if (-not $CompilerPath) { throw '-UseProvidedCompiler requiere -CompilerPath o la variable STUDIOMDL.' }
        $compiler = Test-SplitMeshCompiler (Resolve-Path -LiteralPath $CompilerPath).Path 'Compilador proporcionado'
        $label = 'User-provided compiler; passed functional splitmesh test'
    } else {
        $compiler = Get-TrustedCompiler
        $label = 'FunnkyHD StudioMDL V2.0; verified $splitmesh functional probe'
    }
    $result = Invoke-CompileAndValidate $compiler.Path $label
    exit 0
} catch {
    $failure = [ordered]@{
        status='FAIL_BUILD_NOT_VALIDATED'
        failed_utc=[DateTime]::UtcNow.ToString('o')
        project=$Root
        message=$_.Exception.Message
        official_compiler_page=$OfficialToolUrl
        existing_verified_model_restored_on_compile_validation_failure=$true
        logs_directory=$LogRoot
        reports_directory=$ReportRoot
    }
    $failure | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $ReportRoot 'YORHA_AUTO_BUILD_FAILURE_REPORT.json') -Encoding UTF8
    Write-Host "`nBUILD FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Informe del fallo: $(Join-Path $ReportRoot 'YORHA_AUTO_BUILD_FAILURE_REPORT.json')" -ForegroundColor Yellow
    Write-Host 'No se declarará el MDL como válido si cualquier etapa falla.' -ForegroundColor Yellow
    exit 2
}
