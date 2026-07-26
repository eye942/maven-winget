# Installer authoring

`Prepare-Payload.ps1` emits `artifacts/payload/Components.wxs` from the verified ZIP. WiX Heat produces deterministic IDs from relative paths. The source tree's placeholder fragment is never shipped.
