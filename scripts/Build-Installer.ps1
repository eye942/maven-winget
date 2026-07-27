[CmdletBinding()]
param([Parameter(Mandatory)][string]$MavenVersion,[ValidateSet('stable','maven3-preview','maven4-preview')][string]$Channel,[string]$SourceUrl,[switch]$SkipDownload)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'; Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force
if(-not $Channel){$Channel=Get-MavenChannelForVersion $MavenVersion}
$root=Get-RepositoryRoot;$download=Join-Path $root 'artifacts/downloads';$payload=Join-Path $root 'artifacts/payload';$out=Join-Path $root 'artifacts'; New-Item $out -ItemType Directory -Force|Out-Null
$info=Get-MavenReleaseInfo $MavenVersion $SourceUrl $Channel;$zip=Join-Path $download $info.ArchiveName;$sum="$zip.sha512"
if(!$SkipDownload -or !(Test-Path $zip)){& "$PSScriptRoot/Download-Maven.ps1" -MavenVersion $MavenVersion -Channel $Channel -SourceUrl $SourceUrl -OutputDirectory $download|Out-Null}; & "$PSScriptRoot/Verify-Maven.ps1" -ArchivePath $zip -ChecksumPath $sum|Out-Null
$p=& "$PSScriptRoot/Prepare-Payload.ps1" -ArchivePath $zip -MavenVersion $MavenVersion -OutputDirectory $payload|ConvertFrom-Json
$cfg=Get-RepositoryConfig;$id=Get-PackageIdentifier $Channel;$msi=Join-Path $out "maven-community-$Channel-$MavenVersion-x64.msi";$wix=Get-Command wix -ErrorAction Stop
& $wix.Path build -acceptEula wix7 -bindpath "MavenPayload=$($p.PayloadRoot)" -d "MavenVersion=$MavenVersion" -d "MsiVersion=$(Get-MsiVersion $MavenVersion)" -d "UpgradeCode=$(Get-UpgradeCode)" -d "RepositoryUrl=$($cfg.RepositoryUrl)" -d "ProductName=$(Get-ProductName $Channel)" -d "PackageIdentifier=$id" -arch x64 -out $msi (Join-Path $root 'installer/Product.wxs') (Join-Path $root 'installer/Package.wxs')
if($LASTEXITCODE){throw 'WiX build failed.'}
$meta=[ordered]@{MavenVersion=$MavenVersion;Channel=$Channel;PackageIdentifier=$id;ReleaseTag=(Get-ReleaseTag $MavenVersion $Channel);Scope='Dual';SourceUrl=$info.SourceUrl;ArchiveSha512=(Get-FileHash $zip -Algorithm SHA512).Hash;MsiPath=$msi;MsiSha256=(Get-FileHash $msi -Algorithm SHA256).Hash;MsiSha512=(Get-FileHash $msi -Algorithm SHA512).Hash;BuiltAt=(Get-Date).ToUniversalTime().ToString('o')};$meta|ConvertTo-Json|Set-Content (Join-Path $out 'release-metadata.json');$meta|ConvertTo-Json
