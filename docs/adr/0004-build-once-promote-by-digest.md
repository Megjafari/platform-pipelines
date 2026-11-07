# ADR 0004: Build once, promote by digest

- Status: accepted
- Date: 2026-11-07

## Context

Building an image separately for each environment means that what reaches
production is not what was tested. Base images and dependencies can change
between the builds, even when the source code has not.

## Decision

Build an image once. Promotion adds a tag such as `staging` or `prod` to the
existing digest. The image is rebuilt never, and its bytes do not change.

Before tagging, verify that the digest was signed by `reusable-container` from
the expected repository. After tagging, confirm that the tag points at the digest.
Use `crane tag` because it only writes a tag, unlike a pull, tag and push.

## Consequences

- A signature is required to move on, so an image pushed by hand cannot be promoted.
- Signatures are stored by digest, so they stay valid for every promoted tag.
- A tag can still be moved, so deployments should reference the digest.
- Manual approval for production comes from a GitHub environment with required
  reviewers, which is set up in each repository.
