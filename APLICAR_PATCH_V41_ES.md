# Aplicar parche del workflow V41

1. Haz una copia de seguridad de tu carpeta actual del proyecto Yorha.
2. Extrae `Yorha_AutoBuild_V41_Patch.zip` en la raíz del proyecto y sobrescribe archivos si lo pregunta.
3. Ejecuta `compile_yorha_auto.bat` desde esa raíz.

El parche no incluye StudioMDL ni reemplaza `mesh/`, `anims/` o `textures_windows_1024/`. Sí reemplaza los dos QC para volver al flujo canónico de una SMD de referencia más `$splitmesh 2048`; esto elimina el QC V39 de 47 cuerpos manuales. La carpeta fuente debe contener `mesh/custom_player_highpoly.smd`, `mesh/custom_player_highpoly_windows.smd`, las 393 referencias `anims/*.smd` y `textures_windows_1024/custom_player.bmp`.

El workflow descarga FunnkyHD StudioMDL V2.0 desde la fuente oficial, verifica el archivo, prueba `$splitmesh` con una malla real y solo después compila Yorha. Si el compilador no pasa esa prueba, aborta y no genera un MDL válido de forma ficticia.
