# Publicar y ejecutar el workflow desde Windows

El paquete V43 apunta por defecto al repositorio existente `paladini-maker/mdl-workflow`. El publicador reutiliza el remoto vacío sin crear otro repositorio, publica todo el proyecto, espera el workflow y descarga el MDL/logs/informes. No cambia la visibilidad configurada en GitHub.

## Ejecución

1. Extrae **todo** el ZIP V42 a una carpeta local. No ejecutes el script dentro del visor del ZIP.
2. Abre PowerShell 7 en esa carpeta. La primera ejecución puede instalar Git y GitHub CLI mediante `winget`.
3. Ejecuta:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Deploy-Yorha-GitHub.ps1
```

4. Completa el inicio de sesión web de GitHub cuando lo solicite y autoriza los scopes `repo` y `workflow`.
5. El script inicializa Git si hace falta, confirma el paquete, reutiliza `paladini-maker/mdl-workflow` si existe, hace push y espera GitHub Actions. El repositorio actual es público; los archivos que se publiquen quedarán visibles públicamente. El script no cambia esa visibilidad. Si el evento automático del push no aparece, usa `workflow_dispatch` como respaldo.
6. Al terminar, descarga todos los artefactos a `build/github-actions/run-ID/`, obtiene los logs de tareas fallidas y escribe `build/github-actions/DEPLOYMENT_STATUS.json`.

Se puede cambiar el nombre del repositorio:

```powershell
.\Deploy-Yorha-GitHub.ps1 -RepositoryName mdl-workflow
```

Para un repositorio nuevo, `-Visibility private` o `-Visibility public` determina su visibilidad de creación. En un repositorio ya existente, la visibilidad no se cambia.

Para no esperar al fin del workflow:

```powershell
.\Deploy-Yorha-GitHub.ps1 -SkipWorkflowWait
```

## Qué cuenta como éxito

No basta con que Actions marque el job como `success`. El script exige descargar `yorha.mdl`, `YORHA_AUTO_BUILD_REPORT.json` y `yorha-mdl-structural-validation.json`. Guarda el SHA-256 del MDL descargado y el enlace de la ejecución. La prueba en HLMV/P2MV y dentro de Sven Co-op sigue siendo una validación externa que debe realizarse en el juego.

Si la ejecución falla, revisa `build/github-actions/DEPLOYMENT_FAILURE.json`, `build/github-actions/run-ID/github-actions-failed.log` y los reportes que se hayan descargado. No fuerces el push sobre una rama remota divergente: el script rechaza ese caso para no destruir commits existentes.

## Acceso posterior desde el conector de ChatGPT

Una vez creado el repositorio, debe quedar visible en la conexión GitHub de ChatGPT para que pueda inspeccionar ejecuciones, descargar sus artefactos y preparar correcciones directamente. Si el conector no muestra el repositorio, revisa su instalación/permisos sobre ese repositorio y vuelve a enlazarlo; el login de GitHub CLI de Windows no concede automáticamente acceso al conector.
