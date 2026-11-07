# Architecture

Application repositories call this library instead of keeping their own pipelines.
The library stays in one place and is released with versions, so a fix reaches
every consumer through a version bump.

## How a repository uses the library

```mermaid
flowchart LR
    subgraph consumers [Application repositories]
        app1[.NET service]
        app2[Node site]
        app3[Infrastructure]
    end

    subgraph library [platform-pipelines at v1]
        quality[lint, dotnet-ci, node-ci]
        security[codeql, dependency-review, scheduled-scan]
        iac[iac-validate]
        delivery[container, promote, release, docs-site]
    end

    app1 --> quality
    app1 --> delivery
    app2 --> quality
    app2 --> delivery
    app3 --> iac
    consumers --> security
```

## From commit to verified image

Nothing reaches the registry before the scans pass, and everything after the push
works on the digest, because a tag can be moved. See
[ADR 0003](adr/0003-gate-before-publish-sign-by-digest.md) and
[ADR 0004](adr/0004-build-once-promote-by-digest.md).

```mermaid
flowchart TD
    commit[Commit] --> fs[Scan dependencies]
    fs --> local[Build a local image]
    local --> scan[Scan the image]
    scan -->|findings| stop[Stop, nothing is published]
    scan -->|clean| pr{Pull request?}
    pr -->|yes| build[Multi-arch build without push]
    pr -->|no| push[Multi-arch build and push to GHCR]
    push --> sbom[SBOM]
    sbom --> sign[Keyless cosign signature]
    sign --> attest[Provenance and SBOM attestations]
    attest --> verify[Verify like a consumer]
    verify --> promote[Promote the digest to staging or prod]
    promote --> nightly[Nightly scan of published images]
    nightly -->|new findings| issue[Issue per image]
```

## From commit to release

```mermaid
flowchart LR
    commits[Conventional Commits on main] --> rp[release-please]
    rp --> relpr[Release PR with changelog]
    relpr -->|merged| tag[Tag and GitHub release]
    tag --> major[Move the v1 tag]
    major --> consumers[Consumers on v1 get the update]
```

## How the library is tested

| Layer | Workflow | Question it answers |
| --- | --- | --- |
| Static | `reusable-lint` | Are the workflows themselves valid? |
| Local paths | `ci.yml` and the other callers | Does this branch work on real example code? |
| Released version | `consumer-demo.yml` | Does `@v1` work from the outside? |
| Negative tests | `workflow-tests.yml`, `conftest verify` | Do the gates stop what they should stop? |
