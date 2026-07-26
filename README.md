# Maven Windows Installer

An independently maintained MSI package for the official Apache Maven binary ZIP. **This repository provides an independently maintained Windows installer for Apache Maven. It is not an official Apache Software Foundation distribution and is not endorsed or supported by the Apache Maven project.**

The MSI keeps Maven's complete, unmodified archive tree intact and adds its real `bin` directory to PATH. It exists because Maven's relative-path launchers cannot safely be represented by a detached portable shim.

## Install

After the package is accepted by WinGet:

```powershell
winget install Community.Maven
```

Machine MSI:

```powershell
msiexec /i .\maven-community-<version>-machine-x64.msi ALLUSERS=1
```

User MSI:

```powershell
msiexec /i .\maven-community-<version>-user-x64.msi /qn
```

Open a new terminal after installation. Maven needs a compatible JDK; Java is deliberately not bundled. Maven 3 and Maven 4 have different upstream Java requirements—check the selected release's upstream documentation. To upgrade, install the newer MSI in the same family and scope. Uninstall with `msiexec /x <product-code>` or Apps & Features; it never deletes `%USERPROFILE%\.m2`.

## Build and test

Install .NET 8 SDK, WiX v4 (`dotnet tool install --global wix --version 4.0.5`), and Pester 5. Then:

```powershell
pwsh ./scripts/Build-Installer.ps1 -MavenVersion 3.9.11 -Scope Machine
pwsh ./scripts/Test-Installer.ps1 -MavenVersion 3.9.11
pwsh ./scripts/Generate-WingetManifest.ps1 -MavenVersion 3.9.11 -Scope Machine
```

The build only downloads from Apache-controlled `dlcdn.apache.org`, gets the matching official `.sha512`, and fails closed on mismatch. The release metadata records source and hashes. For a release candidate:

```powershell
pwsh ./scripts/New-Release.ps1 -MavenVersion 3.9.11 -Scope Machine
```

Submit generated files to `microsoft/winget-pkgs` using [the submission guide](docs/winget-submission.md). `winget install --manifest .\manifests\generated\Community.Maven\3.9.11` supports local testing.

## Security and limitations

See [security model](docs/security-model.md). No Authenticode signing is configured by default; consumers should verify release checksums. The central [RepositoryConfig.psd1](RepositoryConfig.psd1) has owner-dependent URLs and package identity. Apache Maven and its trademarks belong to the Apache Software Foundation; this project uses no Apache logo and makes no claim of affiliation.
