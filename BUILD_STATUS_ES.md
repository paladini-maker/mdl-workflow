# Estado del paquete — V32 skinning repair

## Resultado GLB

- `PASS`: GLB 2.0, una malla, 83.436 vértices, 99.998 triángulos, 90 huesos, 3 texturas PBR, 362 animaciones SMD y bind matrices consistentes.
- `PASS`: pesos topológicos anclados (`anchor=0.32`, 12 iteraciones), hasta 4 influencias; sumas normalizadas con error máximo aproximado `1,29e-7`.
- `PASS`: render headless de 362/362 clips, 9 hojas de contacto; 0 posiciones no finitas y 0 clips con triángulos colapsados según el umbral del validador.
- `PASS`: 22 clips críticos en inicio/medio/final, 66 muestras; 0 no finitas y 0 muestras con triángulos colapsados.
- `PARTIAL`: persisten autointersecciones visuales en pelo, manos y extremidades en ciertas poses; se describe la ubicación en `docs/audits/V32_SKINNING_REPAIR_VISUAL_AUDIT_ES.md`.
- `NOT_CHECKED`: Blender interactivo/paint weights, StudioMDL real, readback de MDL y runtime Sven Co-op/Xash.

## Qué se reparó

1. Se descartó el binding por distancia a segmentos óseos porque propagaba influencias a regiones no adyacentes.
2. Se descartó la difusión topológica excesivamente agresiva (`anchor=0.10`, 24 iteraciones); la versión actual limita la difusión con `anchor=0.32`, 12 iteraciones.
3. Se corrigió la orientación de V solo en el render VTK. La textura parecía fragmentada debido a la convención de origen de textura del visualizador, no por las UV de origen de la GLB.
4. Se creó `tools/validate_glb_visual_audit.py` para comprobar que informes, hojas de contacto y métricas están completos.

Ejecutá `python tools/project_audit.py --full --timeout 300` para validar la revisión actual. Un PASS numérico no equivale a calidad artística perfecta ni a prueba in-game.

## Historial V40 — workflow automático con compilador de mayor capacidad documentada para Sven

- Compilador predeterminado: FunnkyHD StudioMDL V2.0 desde la página oficial de GameBanana. No se distribuye el binario; se descarga y cachea localmente.
- El workflow verifica `$splitmesh` con fixture SMD/QC/BMP de 2.050 triángulos y más de 2.048 vértices únicos, y valida el número de bodyparts y los límites por pieza.
- Auditoría de fuentes: PASS; 90 huesos; 99.998 triángulos; 208 secuencias; 393 referencias SMD sin faltantes; 35 hitboxes; 5 controladores; BMP indexado 1024×1024.
- Pruebas de regresión V40: 7/7 PASS en la revisión original; V41 sube a 13/13.
- Compilación final y runtime: NOT RUN en este entorno Linux; automatizados para Windows/GitHub Actions. HLMV/P2MV y Sven Co-op quedan pendientes.


## V41 — ejecución y verificación de extremo a extremo

- Se selecciona FunnkyHD StudioMDL V2.0, la versión documentada con `$splitmesh`, corrección de precisión y auto-partición de `$body` para alta poligonización en GoldSrc/Sven Co-op.
- El workflow se autoabastece del extractor oficial `7zr.exe` si 7-Zip no está instalado; prueba el archivo `.7z` antes de extraer y registra SHA-256 del extractor y del compilador.
- Se ampliaron las pruebas del parser MDL para RLE de animación válido, truncado y con conteos corruptos.
- Estado de esta sesión: preflight de fuentes local aprobado; compilación nativa de Windows aún pendiente porque este entorno no ejecuta `studiomdl.exe`/PowerShell. El job `windows-latest` y el script local ejecutan esa fase real, registran los MDL/logs/JSON y no pueden declarar éxito ante errores.


## V41 — estado final de esta entrega

- 13/13 pruebas de regresión pasan; source preflight confirma 90 huesos, 99.998 triángulos, 208 secuencias, 393 referencias SMD sin faltantes/jerarquías diferentes, 35 hitboxes, 5 controladores y BMP indexado 1024×1024.
- FunnkyHD StudioMDL V2.0 queda como compilador predeterminado. El workflow prueba el `$splitmesh` real con un fixture de 2.050 triángulos y comprueba el MDL resultante antes de intentar compilar Yorha.
- Si no hay 7-Zip, descarga el extractor `7zr.exe` desde el sitio oficial y verifica su hash cacheado, su cabecera y la integridad del `.7z`.
- **Pendiente:** la ejecución nativa del compilador, readback del MDL real, HLMV/P2MV y prueba en Sven Co-op. Este entorno no tiene PowerShell, `studiomdl.exe` ni repositorio GitHub autenticado. El paquete no declara un MDL compilado.


## V43 — destino remoto configurado

- El repositorio `paladini-maker/mdl-workflow` fue confirmado como existente y vacío a través del conector de GitHub; no había ejecuciones de Actions al revisar la API.
- El publicador V43 tiene ese repositorio como destino predeterminado y verifica su visibilidad actual sin cambiarla. El repositorio es público, por lo que una publicación completa expondrá públicamente sus fuentes y recursos.
- Preflight V43: PASS; 90 huesos, 99.998 triángulos, 208 secuencias, 393 referencias de animación sin faltantes ni jerarquías divergentes. Regresión: 17/17.
- **Pendiente:** publicar el árbol completo desde Windows autenticado, ejecutar GitHub Actions y validar un MDL real con los informes binarios. No se afirma que la compilación haya sucedido.
