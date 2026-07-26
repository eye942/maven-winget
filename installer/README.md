# Installer authoring

`Prepare-Payload.ps1` emits `artifacts/payload/Components.wxs` from the verified ZIP. It invokes `heat.exe` from the pinned `WixToolset.Heat` WiX extension cache (or `WIX_HEAT_PATH`), so WiX v4 command-line builds do not depend on an unsupported `wix heat` subcommand. The source tree's placeholder fragment is never shipped.
