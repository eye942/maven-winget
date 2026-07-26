# Installer authoring

`Prepare-Payload.ps1` extracts the verified upstream ZIP into `artifacts/payload`. WiX 7's native `Files` element harvests the entire payload through the named `MavenPayload` bind path; no Heat-generated authoring is used.
