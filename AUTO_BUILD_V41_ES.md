# Yorha V41 — workflow automático de compilación y verificación para Sven Co-op

## Compilador seleccionado

El flujo usa por defecto **FunnkyHD StudioMDL V2.0**, publicado en [la página oficial de FunnkyHD en GameBanana](https://gamebanana.com/tools/6552). Es la opción documentada más apropiada para este modelo y para Sven Co-op: admite `$splitmesh`, corrige la precisión de vértices y subreparte un `$body` grande en partes siempre visibles. Límites documentados que verifica el MDL: 2.048 vértices/normales y 4.080 triángulos por pieza, máximo 64 bodyparts y textura máxima 1024×1024 en Sven. No existe un compilador “ilimitado”: esos son límites prácticos del motor.

El archivo oficial esperado es `funnkyhd-studiomdl_f6dee.7z`. El ejecutable se descarga **en la máquina que compila**, no se redistribuye dentro del ZIP del proyecto. El caché queda en `tools/FunnkyHD_StudioMDL_V2.0/` con SHA-256 del archivo, SHA-256 del EXE, URL de origen, fecha y resultado de la prueba funcional. Esto respeta la licencia publicada del recurso y evita fijar un ejecutable potencialmente viejo dentro del paquete.

## Un solo comando en Windows

Requisitos: Windows 10/11, PowerShell, Python 3.10+ y acceso a Internet para la descarga inicial. Para abrir el archivo `.7z` se usa 7-Zip si ya está instalado; el script prueba también `tar.exe` de Windows. Si no hay 7-Zip instalado, el workflow descarga automáticamente `7zr.exe` desde el sitio oficial de 7-Zip, verifica que sea un PE y que la prueba `7zr t` del archivo pase. No reemplaza el compilador por una versión antigua.

Desde la carpeta raíz del proyecto ejecuta:

```bat
compile_yorha_auto.bat
```

Para forzar una descarga nueva de V2.0 y repetir la prueba del compilador:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\windows\Invoke-YorhaBuild.ps1 -ForceCompilerUpdate
```

Si necesitas probar un `studiomdl.exe` que ya tengas, se puede seleccionar explícitamente; **también debe superar el mismo probe real**:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\windows\Invoke-YorhaBuild.ps1 -UseProvidedCompiler -CompilerPath 'C:\Tools\FunnkyHD\studiomdl.exe'
```

El modo predeterminado no confía en la variable `STUDIOMDL` y no hace fallback silencioso al ejecutable viejo que dio `bad command "$splitmesh"`.

## Pruebas automáticas antes de compilar

1. Ejecuta trece pruebas de regresión del workflow/validador.
2. Comprueba que la prueba de capacidad realmente contiene 2.050 triángulos y más de 2.048 esquinas únicas.
3. Valida el QC, sus directivas y el orden de `$splitmesh 2048` antes del `$body`.
4. Compara el SMD fuente y el Windows: solo admite el cambio vertical UV `V' = 1 - V`; verifica que posiciones, normales, IDs de huesos, materiales y orden de caras no cambien.
5. Recorre las 393 referencias SMD de animación: deben existir y compartir el inventario y la jerarquía de los 90 huesos.
6. Verifica BMP indexado de 1024×1024, 208 secuencias, 99.998 triángulos, 35 hitboxes y 5 controladores.
7. Ejecuta StudioMDL primero sobre un fixture real de SMD/QC/BMP con 2.050 triángulos y más de 2.048 vértices. No basta con que acepte la palabra `$splitmesh`: el MDL de prueba debe mostrar dos o más bodyparts, conservar los 2.050 triángulos y mantener los límites por pieza.

## Verificación del MDL final

Después de compilar `custom_player_windows.qc`, el workflow exige `models/player/yorha/yorha.mdl` y analiza sus bytes. Comprueba firma `IDST`, versión 10, longitud declarada, offsets/tablas dentro del archivo, 90 huesos y jerarquía, 208 nombres y orden de secuencias, streams RLE de animación para todos los canales y blends, 35 hitboxes y 5 controladores, índices de triángulos, paleta, textura de máximo 1024×1024, total exacto de 99.998 triángulos, máximo de 2.048 vértices/normales y 4.080 triángulos por submodelo, y no más de 64 bodyparts.

Se escribe `YORHA_AUTO_BUILD_REPORT.json`, SHA-256 y logs completos. Cualquier comando desconocido, salida parcial, código de retorno distinto de cero o fallo del readback invalida la compilación; el script restaura la última salida MDL verificada y escribe `YORHA_AUTO_BUILD_FAILURE_REPORT.json`. Las carpetas quedan en `build/windows_auto/logs`, `build/windows_auto/reports` y `build/windows_auto/staging`.

Para copiar de forma opcional el resultado a la instalación, define antes `SVENCOOP_ADDON_DIR` apuntando a `svencoop_addon`, no a la carpeta base del juego:

```bat
set "SVENCOOP_ADDON_DIR=C:\Program Files (x86)\Steam\steamapps\common\Sven Co-op\svencoop_addon"
compile_yorha_auto.bat
```

El archivo del juego solo se copia después del readback y se verifica por hash.

## GitHub Actions opcional

`/.github/workflows/yorha-windows-auto-build.yml` ejecuta primero la auditoría en Linux y después descarga, prueba y compila en `windows-latest`. Se puede ejecutar manualmente desde Actions o al cambiar QC, malla, animaciones, textura o scripts. El artefacto incluye el MDL y la evidencia de validación; **no incluye el ejecutable StudioMDL**.

## Estado de esta entrega

- **PASS local:** trece pruebas de regresión; auditoría de origen; 90 huesos; 99.998 triángulos; 208 secuencias; 393 referencias de animación sin archivos faltantes ni jerarquías distintas; UV corregidas; BMP indexado de 1024×1024; probe SMD sintético de 2.050 triángulos.
- **No ejecutado en este entorno:** el binario FunnkyHD de Windows y la compilación nativa del Yorha. Este entorno de trabajo no tiene PowerShell ni puede ejecutar `studiomdl.exe`; el flujo completo se ejecuta en tu Windows o en el job `windows-latest`.
- **Pendiente después de compilar:** inspección en HLMV/P2MV y prueba dentro de Sven Co-op. El informe no marcará esas verificaciones como realizadas.
