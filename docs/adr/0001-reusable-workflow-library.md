# ADR 0001: A library of reusable workflows

- Status: accepted
- Date: 2026-11-06

## Context

Every project needs similar CI: lint, build, test, scan, release. Copying
pipeline files between repositories means a fix or a security improvement has
to be repeated everywhere, and the copies drift apart.

## Decision

Keep shared pipelines in one repository as reusable workflows
(`on: workflow_call`). Consumers call them with `uses:` and pin a version tag
such as `@v1`. This repository tests its own workflows on small example apps.

## Consequences

- A fix is made once and rolled out by bumping the version tag.
- Breaking changes need a new major tag, so older consumers keep working.
- This repository must be public (or explicitly shared) for other repositories
  to call its workflows.
- A broken release affects every consumer, so workflows are tested before they
  are tagged.
