# ADR 0002: Inline install steps instead of composite actions (for now)

- Status: accepted
- Date: 2026-11-06

## Context

The plan included composite actions for shared steps such as installing a
tool. Inside a reusable workflow, a local path like `uses: ./.github/actions/x`
is resolved against the **caller's** repository, not the repository that
contains the workflow. It works when this repository calls its own workflow,
and breaks for every consumer.

The alternative is to reference the action by full name, for example
`Megjafari/platform-pipelines/.github/actions/x@v1`. That makes a workflow
depend on a published tag of the repository it lives in, which complicates
testing changes in a pull request: the tag does not contain the change yet.

## Decision

Keep install and run steps inline in each reusable workflow for now. Add a
composite action only when the same steps are needed in several workflows and
the duplication costs more than the release complexity.

## Consequences

- Workflows are self-contained and can be tested in the pull request that
  changes them.
- A little duplication, such as checksum-verified downloads, is accepted.
- This decision is revisited when a third workflow needs the same step.
