# WinGet submission

Publishing a reviewed draft release automatically starts the WinGet submission workflow. The existing `release` GitHub Environment is the approval boundary for this job. It must contain a `WINGET_CREATE_GITHUB_TOKEN` secret for an account that can fork and open PRs in `microsoft/winget-pkgs`; pull requests, discovery, and draft-release workflows never receive the token.

## Release environment configuration

Configure the repository's `release` environment with these protection rules:

- Require a trusted reviewer before deployment. Enable **Prevent self-review** when a separate maintainer is available, and disable administrator bypass where appropriate.
- Select **Selected branches and tags** as the deployment policy.
- Add these **tag** rules: `v*`, `maven3-preview-v*`, and `maven4-preview-v*`.
- Add this **branch** rule: `main`. It allows recovery-only manual dispatches for an already published release tag.
- Store the WinGet PAT only as the `WINGET_CREATE_GITHUB_TOKEN` environment secret; do not add it as a repository secret.

The tag rules cover automatic runs after stable and preview releases are published. The `main` branch rule covers a maintainer's explicit recovery dispatch; that job still validates the supplied tag and waits for environment approval.

The draft-release job generates the canonical local manifests and runs `Submit-WingetManifest.ps1 -DryRun`. When that draft is published, the protected job derives the channel and version from the release tag, verifies that the matching MSI asset is non-empty, downloads the pinned WingetCreate standalone executable, verifies its SHA-256, and runs `wingetcreate update --submit`. It submits two scope-qualified references to the same release MSI: `x64|user` and `x64|machine`.

## One-time bootstrap

WingetCreate can only update an already accepted package identity. Bootstrap `eye942.Maven` manually first, and bootstrap `eye942.Maven.Maven3Preview` or `eye942.Maven.Maven4Preview` only when their preview channel is ready to list publicly. Use `wingetcreate new` with the corresponding generated manifest bundle as the metadata reference, submit the PR, and wait for it to merge. The CI script fails with these instructions if an upstream identity is missing; it never tries interactive package creation.

## Recovery

The automated run opens a normal upstream PR. A duplicate version means that version is already represented upstream: inspect the existing manifest/PR and do not retry blindly. For installer URL, hash, or schema validation failures, fix the release artifact or canonical generator, publish a corrected release only when appropriate, then use the workflow's `release_tag` manual-dispatch input to resubmit the published release. For local inspection, use:

```powershell
pwsh ./scripts/Submit-WingetManifest.ps1 -MavenVersion 3.9.16 -Channel stable -DryRun
```
