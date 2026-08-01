Describe 'Maven release helpers' {
 BeforeAll { Import-Module "$PSScriptRoot/../../scripts/MavenInstaller.Common.psm1" -Force }
 It 'parses Maven 3 stable versions' { (Get-MavenReleaseInfo '3.9.16').ArchiveName | Should -Be 'apache-maven-3.9.16-bin.zip' }
 It 'parses Maven 4 prereleases' { (Get-MsiVersion '4.0.0-rc-4') | Should -Be '4.0.0.1304' }
 It 'assigns each release channel deterministically' {
   (Get-MavenChannelForVersion '3.9.16') | Should -Be 'stable'
   (Get-MavenChannelForVersion '3.10.0-rc-1') | Should -Be 'maven3-preview'
   (Get-MavenChannelForVersion '4.0.0-rc-5') | Should -Be 'maven4-preview'
 }
 It 'uses eye942 package identifiers per channel' {
   (Get-PackageIdentifier 'stable') | Should -Be 'eye942.Maven'
   (Get-PackageIdentifier 'maven4-preview') | Should -Be 'eye942.Maven.Maven4Preview'
 }
 It 'constructs WingetCreate submission arguments for both scopes' {
   $script = "$PSScriptRoot/../../scripts/Submit-WingetManifest.ps1"
   $submission = & $script -MavenVersion '3.9.16' -Channel stable -DryRun
   $submission.PackageIdentifier | Should -Be 'eye942.Maven'
   $submission.ReleaseAssetUrl | Should -Be 'https://github.com/eye942/maven-winget/releases/download/v3.9.16/maven-community-stable-3.9.16-x64.msi'
   $submission.InstallerUrls | Should -Be @(
     'https://github.com/eye942/maven-winget/releases/download/v3.9.16/maven-community-stable-3.9.16-x64.msi|x64|user',
     'https://github.com/eye942/maven-winget/releases/download/v3.9.16/maven-community-stable-3.9.16-x64.msi|x64|machine'
   )
   $submission.Arguments | Should -Contain '--submit'
 }
 It 'maps preview submission to its upstream package identity' {
   $script = "$PSScriptRoot/../../scripts/Submit-WingetManifest.ps1"
   (& $script -MavenVersion '4.0.0-rc-5' -Channel maven4-preview -DryRun).PackageIdentifier | Should -Be 'eye942.Maven.Maven4Preview'
 }
 It 'refuses a real submission without the protected-environment token' {
   $script = "$PSScriptRoot/../../scripts/Submit-WingetManifest.ps1"
   $existingToken = $env:WINGET_CREATE_GITHUB_TOKEN
   try {
     Remove-Item Env:\WINGET_CREATE_GITHUB_TOKEN -ErrorAction SilentlyContinue
     { & $script -MavenVersion '3.9.16' -Channel stable -WingetCreatePath $script } | Should -Throw '*WINGET_CREATE_GITHUB_TOKEN*'
   } finally {
     if ($null -ne $existingToken) { $env:WINGET_CREATE_GITHUB_TOKEN = $existingToken }
   }
 }
 It 'keeps WinGet submission out of pull-request workflows' {
   $releaseWorkflow = Get-Content -Raw "$PSScriptRoot/../../.github/workflows/release.yml"
   $releaseWorkflow | Should -Match 'environment: release'
   $releaseWorkflow | Should -Match 'WINGET_CREATE_GITHUB_TOKEN: \$\{\{ secrets\.WINGET_CREATE_GITHUB_TOKEN \}\}'
   $releaseWorkflow | Should -Not -Match '(?m)^\s*pull_request:'
   (Get-Content -Raw "$PSScriptRoot/../../.github/workflows/validate-winget.yml") | Should -Not -Match 'WINGET_CREATE_GITHUB_TOKEN'
 }
 It 'prepares draft releases only from trusted known automation branches' {
   $prepareWorkflow = Get-Content -Raw "$PSScriptRoot/../../.github/workflows/prepare-release.yml"
   $prepareWorkflow | Should -Match 'target_commitish: \$\{\{ steps\.source\.outputs\.commit \}\}'
   $prepareWorkflow | Should -Match 'head\.repo\.full_name == github\.repository'
   $prepareWorkflow | Should -Match "head\.ref == 'automation/maven-stable'"
   $prepareWorkflow | Should -Match "head\.ref == 'automation/maven-maven3-preview'"
   $prepareWorkflow | Should -Match "head\.ref == 'automation/maven-maven4-preview'"
   $prepareWorkflow | Should -Not -Match 'startsWith\(github\.event\.pull_request\.head\.ref'
 }
 It 'rejects a version in the wrong channel' { { Get-MavenReleaseInfo '3.9.16' -Channel 'maven3-preview' } | Should -Throw }
 It 'parses the Apache publish date and a stable ZIP' {
   $html='<li id="publishDate"><span>Last Published:</span> 2026-07-01</li><a href="https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.zip">ZIP</a>'
   $release=ConvertFrom-MavenDownloadPage -Html $html -Channel stable
   $release.Version | Should -Be '3.9.16'; $release.PublishDate | Should -Be '2026-07-01'
 }
 It 'fails closed when Apache publish date is missing' { { ConvertFrom-MavenDownloadPage -Html '<html />' -Channel stable } | Should -Throw }
 It 'constructs official URLs' { (Get-MavenReleaseInfo '3.9.16').SourceUrl | Should -Match '^https://dlcdn.apache.org/maven/' }
 It 'rejects bad versions' { { Assert-MavenVersion 'x' } | Should -Throw }
 It 'extracts official checksums' { Get-OfficialSha512 ('a'*128) | Should -Be ('a'*128) }
 It 'formats paths with spaces' { Get-PathEntry 'C:\Program Files\Apache Maven\apache-maven-3.9.16' | Should -Be 'C:\Program Files\Apache Maven\apache-maven-3.9.16\bin' }
 It 'recognizes a duplicate PATH entry' { Test-PathEntryPresent 'C:\a;C:\b\bin' 'C:\b\bin' | Should -BeTrue }
}
