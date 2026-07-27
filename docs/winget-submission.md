# WinGet submission

Published releases submit their WinGet update automatically. The `winget-submission` GitHub Environment must contain a `WINGET_CREATE_GITHUB_TOKEN` secret for an account that can fork and open PRs in `microsoft/winget-pkgs`. This protected environment is used only by the post-publication job in `release.yml`; pull requests, discovery, and draft-release workflows never receive the token.

The release job generates the canonical local manifests and runs `Submit-WingetManifest.ps1 -DryRun`. After the GitHub Release upload succeeds, the protected job downloads the pinned WingetCreate standalone executable, verifies its SHA-256, and runs `wingetcreate update --submit`. It submits two scope-qualified references to the same release MSI: `x64|user` and `x64|machine`.

## One-time bootstrap

WingetCreate can only update an already accepted package identity. Bootstrap `eye942.Maven` manually first, and bootstrap `eye942.Maven.Maven3Preview` or `eye942.Maven.Maven4Preview` only when their preview channel is ready to list publicly. Use `wingetcreate new` with the corresponding generated manifest bundle as the metadata reference, submit the PR, and wait for it to merge. The CI script fails with these instructions if an upstream identity is missing; it never tries interactive package creation.

## Recovery

The automated run opens a normal upstream PR. A duplicate version means that version is already represented upstream: inspect the existing manifest/PR and do not retry blindly. For installer URL, hash, or schema validation failures, fix the release artifact or canonical generator, publish a corrected release only when appropriate, then run the release workflow for the intended version. For local inspection, use:

```powershell
pwsh ./scripts/Submit-WingetManifest.ps1 -MavenVersion 3.9.16 -Channel stable -DryRun
```
