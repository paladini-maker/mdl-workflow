# Yorha V43 — compilación automática para Sven Co-op

## Publicar en el repositorio existente y ejecutar automáticamente (V43)

Para subir el paquete completo a [`paladini-maker/mdl-workflow`](https://github.com/paladini-maker/mdl-workflow), iniciar Actions, esperar el resultado y descargar el MDL/logs/informes desde Windows, sigue [`GITHUB_DEPLOY_ES_V43.md`](GITHUB_DEPLOY_ES_V43.md) o [`DEPLOY_TO_EXISTING_REPO_V43.md`](DEPLOY_TO_EXISTING_REPO_V43.md). El publicador apunta a `mdl-workflow` por defecto, puede instalar Git/GitHub CLI con `winget`, solicita la autorización web oficial cuando falta y no fuerza el push sobre una historia remota divergente.

El conector GitHub de ChatGPT necesita acceso propio al repositorio después de crearlo; la sesión de `gh` en Windows no le otorga permisos automáticamente.

## Ejecutar el workflow

En Windows 10/11, con Python 3.10+ e Internet disponible, extrae el paquete, abre CMD en `Yorha_Windows_AutoBuild_V43` y ejecuta:

```bat
compile_yorha_auto.bat
```

El flujo descarga FunnkyHD StudioMDL V2.0 de la página oficial de [GameBanana](https://gamebanana.com/tools/6552), selecciona el ejecutable por defecto y valida que `$splitmesh` funcione en una prueba real antes de compilar Yorha. Si no hay 7-Zip instalado, descarga `7zr.exe` desde [el sitio oficial de 7-Zip](https://www.7-zip.org/download.html), registra su SHA-256 y prueba la integridad del archivo `.7z` antes de extraer.

No se usa `$resizetexture`; el QC apunta al BMP indexado de 1024×1024 que ya está preparado. No hay fallback silencioso a un compilador viejo. Si una prueba falla, el workflow aborta, genera `YORHA_AUTO_BUILD_FAILURE_REPORT.json` y restaura el último MDL verificado.

## Qué verifica

El preflight local comprueba 90 huesos, 99.998 triángulos, 208 secuencias, 393 referencias SMD de animación sin faltantes ni jerarquías distintas, 35 hitboxes, 5 controladores, UV corregidas y textura BMP indexada de 1024×1024. La regresión del workflow tiene **17 pruebas** en este paquete V43.

Antes de compilar la malla completa, FunnkyHD debe superar la prueba SMD/QC/BMP de 2.050 triángulos y más de 2.048 vértices; el MDL de prueba debe contener varias piezas, conservar todos los triángulos y respetar límites por pieza. Tras compilar Yorha, el lector binario verifica IDST v10, tablas y offsets, huesos, jerarquía, animaciones RLE, secuencias, hitboxes, controladores, texturas, índices, total de triángulos y límites por pieza.

## Compilador de mayor capacidad práctica para este objetivo

La opción seleccionada es FunnkyHD StudioMDL V2.0 porque documenta `$splitmesh`, corrige precisión de vértices y divide un `$body` de alta poligonización en piezas visibles. No hay un compilador «ilimitado»: para Sven Co-op se validan 2.048 vértices/normales, 4.080 triángulos por pieza, hasta 64 bodyparts y texturas de hasta 1024×1024. Estos límites se verifican en el MDL real; la prueba de capacidad no se sustituye por buscar la palabra `$splitmesh` en el QC.

Para forzar descarga limpia del compilador y repetir la prueba:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\windows\Invoke-YorhaBuild.ps1 -ForceCompilerUpdate
```

Para usar un ejecutable de StudioMDL específico, también deberá superar la prueba funcional:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\windows\Invoke-YorhaBuild.ps1 -UseProvidedCompiler -CompilerPath 'C:\Tools\FunnkyHD\studiomdl.exe'
```

Opcionalmente, define `SVENCOOP_ADDON_DIR` apuntando a `svencoop_addon` para copiar el MDL solamente después de superar el readback y comprobar su hash.

## Evidencia y estado

- `validation/REGRESSION_TESTS_V41.txt`: informe histórico de V41; el paquete V43 ejecuta 17 pruebas actuales.
- `validation/source-preflight-v41.json`: inventario y revisión de los recursos originales.
- `validation/LOCAL_STATIC_VERIFICATION_V41.json`: auditoría estática de scripts y workflow.
- `WORKFLOW_EXECUTION_STATUS_V42.json`: historial de V42. `WINDOWS_FILE_MANIFEST_V43.json` y `SHA256SUMS_V43.txt` identifican los archivos de esta entrega.
- `.github/workflows/yorha-windows-auto-build.yml`: workflow opcional que compila en un runner Windows real y publica MDL/logs/informes como artefacto.

**Importante:** en este entorno Linux no están disponibles Windows PowerShell ni `studiomdl.exe`, y no hay un repositorio GitHub autenticado donde ejecutar Actions. Por eso la compilación real del MDL, HLMV/P2MV y prueba dentro de Sven Co-op siguen marcadas como pendientes. El workflow no reporta un MDL compilado hasta que esas verificaciones binarias pasan.
