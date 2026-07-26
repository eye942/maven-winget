[CmdletBinding()] param([Parameter(Mandatory)][string]$ArchivePath,[Parameter(Mandatory)][string]$MavenVersion,[string]$OutputDirectory=(Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts/payload'))
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'; Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force; Assert-MavenVersion $MavenVersion
if(Test-Path $OutputDirectory){Remove-Item -LiteralPath $OutputDirectory -Recurse -Force}; New-Item -ItemType Directory -Path $OutputDirectory|Out-Null
Expand-Archive -LiteralPath $ArchivePath -DestinationPath $OutputDirectory -Force
$root=Join-Path $OutputDirectory "apache-maven-$MavenVersion"; if(!(Test-Path $root)){throw "Archive did not contain expected root apache-maven-$MavenVersion."}; if(!(Test-Path (Join-Path $root 'bin/mvn.cmd'))){throw 'Archive does not contain bin/mvn.cmd.'}
[pscustomobject]@{PayloadRoot=$root}|ConvertTo-Json
