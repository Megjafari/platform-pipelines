# platform-pipelines

A library of reusable CI/CD workflows. Instead of copying pipelines between
projects, a repository calls the workflow it needs and pins a version:

```yaml
jobs:
  ci:
    uses: OWNER/platform-pipelines/.github/workflows/reusable-dotnet-ci.yml@v1
    with:
      dotnet-version: "10.0.x"
```

Fix something once here, and every consumer gets it by bumping the version.

> **Status:** under construction. Scaffold, `reusable-lint` and `reusable-container` are done.
> The catalog below shows what is planned and what already exists.

## Catalog

| Workflow | Purpose | Status |
| --- | --- | --- |
| [`reusable-lint`](#reusable-lint) | actionlint, yamllint, gitleaks | available |
| `reusable-dotnet-ci` | .NET 10 build, test, coverage, format check | planned |
| `reusable-node-ci` | npm / pnpm / yarn: lint, typecheck, test, build | planned |
| [`reusable-container`](#reusable-container) | multi-arch build, SBOM, Trivy, cosign, provenance, GHCR | available |
| `reusable-iac-validate` | Terraform, kubeconform, conftest policies | planned |
| `reusable-release` | conventional commits and release-please | planned |
| `reusable-docs-site` | Markdown to GitHub Pages | planned |
| `reusable-pr-checks` | PR title, labels, size, description | planned |
| `reusable-codeql` | SAST for C# and JavaScript | planned |
| `reusable-dependency-review` | block vulnerable or badly licensed dependencies | planned |
| `reusable-lighthouse` | performance / accessibility budgets | planned |

### reusable-lint

Lints GitHub Actions workflows (actionlint), YAML (yamllint) and scans the git
history for secrets (gitleaks, checksum-verified install).

```yaml
jobs:
  lint:
    uses: OWNER/platform-pipelines/.github/workflows/reusable-lint.yml@v1
    permissions:
      contents: read
```

| Input | Default | Description |
| --- | --- | --- |
| `run-actionlint` | `true` | Lint workflows with actionlint |
| `run-yamllint` | `true` | Lint YAML; uses the caller's `.yamllint` if present |
| `run-gitleaks` | `true` | Scan history for secrets; uses the caller's `.gitleaks.toml` if present |
| `yamllint-strict` | `true` | Treat yamllint warnings as errors |
| `actionlint-version` | `1.7.7` | Pinned tool version |
| `yamllint-version` | `1.35.1` | Pinned tool version |
| `gitleaks-version` | `8.21.2` | Pinned tool version |

### reusable-container

Scans the build context, builds a local image and scans that too. Only if both
pass does it build for all platforms and push to GHCR. After the push it creates
an SPDX SBOM, signs with cosign (keyless) and adds GitHub attestations, all on the
digest, and then verifies the result. Pull requests build and scan but never push.

```yaml
jobs:
  container:
    uses: OWNER/platform-pipelines/.github/workflows/reusable-container.yml@v1
    permissions:
      contents: read
      packages: write
      id-token: write
      attestations: write
```

| Input | Default | Description |
| --- | --- | --- |
| `context` | `.` | Docker build context |
| `dockerfile` | `<context>/Dockerfile` | Path to the Dockerfile |
| `image` | `ghcr.io/<owner>/<repo>` | Image name without tag |
| `platforms` | `linux/amd64,linux/arm64` | Target platforms |
| `push` | `true` | Push the image (never on `pull_request`) |
| `attest` | `true` | GitHub attestations; set `false` on private repositories without Enterprise |
| `trivy-severity` | `CRITICAL,HIGH` | Severities that fail the build |
| `trivy-ignore-unfixed` | `true` | Ignore vulnerabilities without a fix |
| `trivy-version` | `0.76.2` | Pinned tool version |

Outputs: `image` and `digest` (empty when nothing was pushed).

Verify a published image:

```bash
cosign verify ghcr.io/OWNER/IMAGE@sha256:DIGEST \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github\.com/.+/\.github/workflows/reusable-container\.yml@' \
  --certificate-github-workflow-repository OWNER/REPO
```

## Repository layout

```
.github/workflows/   workflows (reusable-*.yml are the library, the rest is this repo's own CI)
.github/actions/     composite actions shared between workflows
examples/            small apps the workflows are tested against
policies/            Rego policies used by conftest
docs/                architecture notes and ADRs
```

## Development

Linting runs through Docker so nothing needs to be installed locally:

```bash
make lint
```

## Principles

- **Least privilege:** every workflow declares its own minimal `permissions:`.
- **Pinned and updated:** actions are pinned and kept current by Renovate.
- **Tested:** workflows are linted, and security gates have negative tests.
- **Decisions are written down:** see [docs/adr](docs/adr).

## License

To be decided before the repository is made public.
