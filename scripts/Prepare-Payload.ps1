[CmdletBinding()] param([Parameter(Mandatory)][string]$ArchivePath,[Parameter(Mandatory)][string]$MavenVersion,[string]$OutputDirectory=(Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts/payload'))
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'; Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force; Assert-MavenVersion $MavenVersion
if(Test-Path $OutputDirectory){Remove-Item -LiteralPath $OutputDirectory -Recurse -Force}; New-Item -ItemType Directory -Path $OutputDirectory|Out-Null
Expand-Archive -LiteralPath $ArchivePath -DestinationPath $OutputDirectory -Force
$root=Join-Path $OutputDirectory "apache-maven-$MavenVersion"; if(!(Test-Path $root)){throw "Archive did not contain expected root apache-maven-$MavenVersion."}; if(!(Test-Path (Join-Path $root 'bin/mvn.cmd'))){throw 'Archive does not contain bin/mvn.cmd.'}
$heatPath=$env:WIX_HEAT_PATH
if([string]::IsNullOrWhiteSpace($heatPath)){
    $heatCache=Join-Path $env:USERPROFILE '.wix\extensions\WixToolset.Heat'
    $heat=Get-ChildItem -LiteralPath $heatCache -Recurse -Filter heat.exe -File -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
    if($heat){$heatPath=$heat.FullName}
}
if([string]::IsNullOrWhiteSpace($heatPath) -or -not (Test-Path -LiteralPath $heatPath)){throw 'WiX Heat executable was not found. Install WixToolset.Heat/4.0.5 with `wix extension add -g WixToolset.Heat/4.0.5`, or set WIX_HEAT_PATH.'}
$fragment=Join-Path $OutputDirectory 'Components.wxs'; & $heatPath dir $root -dr INSTALLDIR -cg MavenPayload -gg -srd -sfrag -out $fragment
if($LASTEXITCODE){throw "WiX Heat failed with exit code $LASTEXITCODE. Review Heat output above."}
[pscustomobject]@{PayloadRoot=$root;FragmentPath=$fragment}|ConvertTo-Json
