# ADR 0003: Scan before publishing, sign by digest

- Status: accepted
- Date: 2026-11-06

## Context

An image scanned after it has been pushed is already available to anyone who
can pull it. Tags can also be moved, so a signature on a tag says little about
what was actually built.

## Decision

- Scan the build context and a local single-arch build first. The multi-arch
  build and the push only run if both scans pass.
- Sign, attest and verify the digest returned by the push, never a tag.
- Use keyless signing with the workflow's GitHub OIDC identity, so there are no
  long-lived signing keys to store or rotate.
- Verify inside the workflow, the same way a consumer would.

## Consequences

- Only `linux/amd64` passes through the image gate. The other platforms share
  the same Dockerfile but are not scanned separately.
- The signing identity is the reusable workflow, so `cosign verify` matches on
  that workflow and on the calling repository.
- Keyless signing writes to the public Sigstore transparency log. For a private
  repository, this exposes its name and the image digest.
- GitHub attestations need a public repository (or GitHub Enterprise), so they
  are an input. `gh attestation verify` uses `--owner`, which assumes that the
  consumer and this library have the same owner.
