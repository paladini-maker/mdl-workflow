# Publicar en paladini-maker/mdl-workflow (V43)

El repositorio ya existe y está vacío. No se debe crear otro ni agregar un commit remoto inicial separado, porque eso genera una historia divergente respecto del primer push completo.

1. Extrae el ZIP completo V43 en Windows 10/11.
2. Abre PowerShell en `Yorha_Windows_AutoBuild_V43`.
3. Ejecuta:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Deploy-Yorha-GitHub.ps1
```

El publicador predetermina `-RepositoryName mdl-workflow`, autentica GitHub CLI si es necesario, verifica permisos `repo,workflow`, publica el árbol del paquete completo y espera la ejecución de Actions. Descarga los artefactos/logs bajo `build\github-actions\`. Si falla, conserva `DEPLOYMENT_FAILURE.json`, `DEPLOYMENT_STATUS.json` y los logs.

**Aviso de privacidad:** GitHub informa que `paladini-maker/mdl-workflow` es público. El script mantiene esa configuración y no cambia su visibilidad. Publicar el paquete completo también publicará públicamente los archivos fuente, texturas y animaciones.

La compilación solo queda validada si se descargan `yorha.mdl`, `YORHA_AUTO_BUILD_REPORT.json` y `yorha-mdl-structural-validation.json`. HLMV/P2MV y el arranque dentro de Sven Co-op siguen siendo pruebas manuales.
