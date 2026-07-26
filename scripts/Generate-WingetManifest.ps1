[CmdletBinding()] param([Parameter(Mandatory)][string]$MavenVersion,[string]$MsiPath,[string]$ReleaseUrl)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop';Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force
$root=Get-RepositoryRoot;$cfg=Get-RepositoryConfig;if(!$MsiPath){$MsiPath=Join-Path $root "artifacts/maven-community-$MavenVersion-x64.msi"};if(!(Test-Path $MsiPath)){throw "MSI not found: $MsiPath"};if(!$ReleaseUrl){$ReleaseUrl="$($cfg.RepositoryUrl)/releases/download/v$MavenVersion/$(Split-Path $MsiPath -Leaf)"}
$dir=Join-Path $root "manifests/generated/$($cfg.PackageIdentifier)/$MavenVersion";New-Item -ItemType Directory -Force -Path $dir|Out-Null;$hash=(Get-FileHash $MsiPath -Algorithm SHA256).Hash;$date=(Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
@"
PackageIdentifier: $($cfg.PackageIdentifier)
PackageVersion: $MavenVersion
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.6.0
"@|Set-Content "$dir/$($cfg.PackageIdentifier).yaml"
@"
PackageIdentifier: $($cfg.PackageIdentifier)
PackageVersion: $MavenVersion
PackageLocale: en-US
Publisher: $($cfg.Publisher)
PublisherUrl: $($cfg.RepositoryUrl)
PackageName: $($cfg.PackageName)
PackageUrl: $($cfg.RepositoryUrl)
License: Apache-2.0
LicenseUrl: $($cfg.LicenseUrl)
ShortDescription: Community-maintained MSI installer for Apache Maven.
Description: Independently maintained Windows MSI packaging for Apache Maven. Not endorsed or supported by the Apache Software Foundation.
ReleaseNotesUrl: $($cfg.RepositoryUrl)/releases/tag/v$MavenVersion
ReleaseDate: $date
InstallationNotes: A compatible JDK is required. This installer does not bundle Java.
ManifestType: defaultLocale
ManifestVersion: 1.6.0
"@|Set-Content "$dir/$($cfg.PackageIdentifier).locale.en-US.yaml"
@"
PackageIdentifier: $($cfg.PackageIdentifier)
PackageVersion: $MavenVersion
InstallerType: wix
UpgradeBehavior: install
Commands:
- mvn
- mvnDebug
Installers:
- Architecture: x64
  InstallerUrl: $ReleaseUrl
  InstallerSha256: $hash
  InstallerType: wix
  Scope: user
  InstallerSwitches:
    Custom: ALLUSERS=2 MSIINSTALLPERUSER=1
- Architecture: x64
  InstallerUrl: $ReleaseUrl
  InstallerSha256: $hash
  InstallerType: wix
  Scope: machine
  InstallerSwitches:
    Custom: ALLUSERS=1 MSIINSTALLPERUSER=""
ManifestType: installer
ManifestVersion: 1.6.0
"@|Set-Content "$dir/$($cfg.PackageIdentifier).installer.yaml"
Write-Output $dir
