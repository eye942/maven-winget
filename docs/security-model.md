# Security model

Apache controls the source ZIP and checksum; this community project controls only repackaging. TLS and the official SHA-512 file are required and a mismatch stops the build. Optional GPG support is deliberately non-authoritative until a managed Apache KEYS trust workflow is configured.

Actions use read-only defaults and are pinned where practical. Pull requests do not receive secrets. Release permissions are narrowly scoped to contents write and can later call a signing service through protected secrets without changing MSI structure. No signing key is committed; absent Authenticode signing is disclosed in releases.

Risks include a compromised mirror, runner/action supply chain, or malicious contribution. Reviewable scripts, hash records, PR review, artifact retention, and release environments mitigate but do not eliminate them. Java is not bundled, reducing third-party supply-chain scope. The installer only owns its installation root and PATH value; it never modifies or deletes user Maven repositories.
