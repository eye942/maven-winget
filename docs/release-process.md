# Release process

1. The weekly discovery workflow reads Apache's `download.cgi` and its `#publishDate` for the stable, Maven 3 preview, and Maven 4 preview streams. It opens one review PR per channel.
2. Review the PR's upstream ZIP and checksum URLs. CI independently verifies SHA-512, builds the channel MSI, and attaches the release-preview bundle.
3. Merge the candidate PR. `prepare-release.yml` rebuilds from verified inputs and creates a channel-specific GitHub draft release.
4. Review the draft. Dispatch `release.yml` with the exact version and channel to publish it; this rebuilds and verifies before publication.
5. After GitHub Release publication succeeds, the protected `winget-submission` environment runs WingetCreate and opens the update PR in `microsoft/winget-pkgs`.

The streams are `eye942.Maven`, `eye942.Maven.Maven3Preview`, and `eye942.Maven.Maven4Preview`. Preview streams never replace the stable package identity, but their MSI installation deliberately replaces another active Maven channel in the same scope so that `mvn` stays unambiguous.
