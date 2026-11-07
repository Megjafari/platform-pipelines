# platform-pipelines

A library of reusable CI/CD workflows. See the
[repository](https://github.com/Megjafari/platform-pipelines) for the catalog and
usage examples.

Start with the [architecture](architecture.md).

## Decisions

The reasoning behind the design is recorded as architecture decision records:

- [ADR 0001: A library of reusable workflows](adr/0001-reusable-workflow-library.md)
- [ADR 0002: Inline install steps instead of composite actions](adr/0002-no-composite-actions-for-now.md)
- [ADR 0003: Scan before publishing, sign by digest](adr/0003-gate-before-publish-sign-by-digest.md)
- [ADR 0004: Build once, promote by digest](adr/0004-build-once-promote-by-digest.md)
