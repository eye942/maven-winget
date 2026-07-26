# WinGet submission

Build and publish a reviewed GitHub Release, generate manifests, fork `microsoft/winget-pkgs`, then run:

```powershell
pwsh ./scripts/Copy-WingetManifests.ps1 -WingetPkgsPath C:\src\winget-pkgs -MavenVersion 3.9.16
```

The helper copies to `manifests/c/Community/Maven/<version>` only; it never pushes. Validate with `winget validate --manifest <path>` where available, commit in the fork, and open a PR. Address automated hash, URL, schema, or metadata feedback and repeat for each upstream release.
