# Maven Windows Installer

An independently maintained MSI package for the official Apache Maven binary ZIP. **This repository provides an independently maintained Windows installer for Apache Maven. It is not an official Apache Software Foundation distribution and is not endorsed or supported by the Apache Maven project.**

The MSI keeps Maven's complete, unmodified archive tree intact and adds its real `bin` directory to PATH. It exists because Maven's relative-path launchers cannot safely be represented by a detached portable shim.

## Install

After the package is accepted by WinGet:

```powershell
winget install eye942.Maven
```

Machine MSI:

```powershell
msiexec /i .\maven-community-stable-<version>-x64.msi ALLUSERS=1 MSIINSTALLPERUSER=""
```

User MSI:

```powershell
msiexec /i .\maven-community-stable-<version>-x64.msi ALLUSERS=2 MSIINSTALLPERUSER=1 /qn
```

Open a new terminal after installation. Maven needs a compatible JDK; Java is deliberately not bundled. Maven 3 and Maven 4 have different upstream Java requirements—check the selected release's upstream documentation. To upgrade, install the newer MSI in the same family and scope. Installing a preview or switching back to stable replaces the existing Maven channel in that scope, so only one `mvn` remains on `PATH`. Uninstall with `msiexec /x <product-code>` or Apps & Features; it never deletes `%USERPROFILE%\.m2`.

## Release channels

`eye942.Maven` is the stable channel. `eye942.Maven.Maven3Preview` and `eye942.Maven.Maven4Preview` are independent prerelease channels for testing upcoming Maven 3 and Maven 4 releases. Preview packages are explicitly marked as prereleases; do not use them as unattended production upgrades.

## Build and test

Install .NET 8 SDK, WiX v7 (`dotnet tool install --global wix --version 7.0.0`), and Pester 5. By building, maintainers accept the WiX 7 `wix7` OSMF EULA as authorized for this project. Then:

```powershell
wix eula accept wix7
pwsh ./scripts/Build-Installer.ps1 -MavenVersion 3.9.16
pwsh ./scripts/Test-Installer.ps1 -MavenVersion 3.9.16
pwsh ./scripts/Generate-WingetManifest.ps1 -MavenVersion 3.9.16
```

The build only downloads from Apache-controlled `dlcdn.apache.org`, gets the matching official `.sha512`, and fails closed on mismatch. The release metadata records source and hashes. For a release candidate:

```powershell
pwsh ./scripts/New-Release.ps1 -MavenVersion 3.9.16 -Channel stable
```

Published releases automatically submit updates to `microsoft/winget-pkgs`; see [the submission guide](docs/winget-submission.md) for protected-environment setup and the one-time package bootstrap. `winget install --manifest .\manifests\generated\eye942.Maven\3.9.16` supports local testing.

## Security and limitations

See [security model](docs/security-model.md). No Authenticode signing is configured by default; consumers should verify release checksums. The central [RepositoryConfig.psd1](RepositoryConfig.psd1) has owner-dependent URLs and package identity. Apache Maven and its trademarks belong to the Apache Software Foundation; this project uses no Apache logo and makes no claim of affiliation.
