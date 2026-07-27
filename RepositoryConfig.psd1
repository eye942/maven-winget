@{
    Publisher = 'eye942 Community Maintainers'
    RepositoryUrl = 'https://github.com/eye942/maven-winget'
    LicenseUrl = 'https://www.apache.org/licenses/LICENSE-2.0'
    DefaultMavenVersion = '3.9.16'
    WixVersion = '7.0.0'
    # A single upgrade family deliberately permits a channel switch while ensuring
    # that only one Maven bin directory remains active on PATH for each scope.
    MavenUpgradeCode = '{BC8F546E-66E0-43B4-BF19-0915F3BF5D98}'
    Channels = @{
        stable = @{
            PackageIdentifier = 'eye942.Maven'
            ProductName = 'Apache Maven Community Windows Installer'
            BranchPrefix = 'automation/maven-stable-'
            ReleaseTagPrefix = 'v'
            IsPrerelease = $false
        }
        'maven3-preview' = @{
            PackageIdentifier = 'eye942.Maven.Maven3Preview'
            ProductName = 'Apache Maven 3 Preview Community Windows Installer'
            BranchPrefix = 'automation/maven-maven3-preview-'
            ReleaseTagPrefix = 'maven3-preview-v'
            IsPrerelease = $true
        }
        'maven4-preview' = @{
            PackageIdentifier = 'eye942.Maven.Maven4Preview'
            ProductName = 'Apache Maven 4 Preview Community Windows Installer'
            BranchPrefix = 'automation/maven-maven4-preview-'
            ReleaseTagPrefix = 'maven4-preview-v'
            IsPrerelease = $true
        }
    }
}
