# Fuentes y licencias

La lista activa y las restricciones de uso se consolidaron en [`docs/REFERENCES_LICENSES_ES.md`](docs/REFERENCES_LICENSES_ES.md). Los informes completos se conservan en [`docs/audits/`](docs/audits/).

No copiar, instalar ni redistribuir código de un backend externo sin confirmar licencia/procedencia, versión, hash del artefacto y resultado de pruebas aisladas. Compartir la extensión `.mdl` no significa compartir el formato binario.

## FunnkyHD StudioMDL V2.0 (V41 auto-build)

- Official page and download metadata: https://gamebanana.com/tools/6552
- The workflow fetches the published `funnkyhd-studiomdl_f6dee.7z` only at build time; it does not redistribute the licensed compiler executable.
- A real 2,050-triangle SMD/QC/BMP fixture must be compiled first; the workflow checks the emitted MDL to confirm it split into multiple visible bodyparts and preserved every triangle before starting Yorha.

- 7-Zip fallback extractor is fetched from https://www.7-zip.org/a/7zr.exe only when needed; it is tested against the downloaded archive before extraction and is not bundled.
