[CmdletBinding()] param([Parameter(Mandatory)][string]$MavenVersion,[ValidateSet('stable','maven3-preview','maven4-preview')][string]$Channel,[string]$MsiPath,[string]$ReleaseUrl)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop';Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force
if(-not $Channel){$Channel=Get-MavenChannelForVersion $MavenVersion}
$root=Get-RepositoryRoot;$cfg=Get-RepositoryConfig;$id=Get-PackageIdentifier $Channel;$product=Get-ProductName $Channel;$tag=Get-ReleaseTag $MavenVersion $Channel
if(!$MsiPath){$MsiPath=Join-Path $root "artifacts/maven-community-$Channel-$MavenVersion-x64.msi"};if(!(Test-Path $MsiPath)){throw "MSI not found: $MsiPath"};if(!$ReleaseUrl){$ReleaseUrl="$($cfg.RepositoryUrl)/releases/download/$tag/$(Split-Path $MsiPath -Leaf)"}
$dir=Join-Path $root "manifests/generated/$id/$MavenVersion";New-Item -ItemType Directory -Force -Path $dir|Out-Null;$hash=(Get-FileHash $MsiPath -Algorithm SHA256).Hash;$date=(Get-Date).ToUniversalTime().ToString('yyyy-MM-dd');$channelNote=if($Channel -eq 'stable'){'Stable Maven channel.'}else{"$Channel channel; this is a Maven preview release."}
@"
PackageIdentifier: $id
PackageVersion: $MavenVersion
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.6.0
"@|Set-Content "$dir/$id.yaml"
@"
PackageIdentifier: $id
PackageVersion: $MavenVersion
PackageLocale: en-US
Publisher: $($cfg.Publisher)
PublisherUrl: $($cfg.RepositoryUrl)
PackageName: $product
PackageUrl: $($cfg.RepositoryUrl)
License: Apache-2.0
LicenseUrl: $($cfg.LicenseUrl)
ShortDescription: Community-maintained MSI installer for Apache Maven.
Description: Independently maintained Windows MSI packaging for Apache Maven. Not endorsed or supported by the Apache Software Foundation.
ReleaseNotesUrl: $($cfg.RepositoryUrl)/releases/tag/$tag
ReleaseDate: $date
InstallationNotes: A compatible JDK is required. This installer does not bundle Java. $channelNote Installing this channel replaces another active Maven channel in the same scope.
ManifestType: defaultLocale
ManifestVersion: 1.6.0
"@|Set-Content "$dir/$id.locale.en-US.yaml"
@"
PackageIdentifier: $id
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
"@|Set-Content "$dir/$id.installer.yaml"
Write-Output $dir
