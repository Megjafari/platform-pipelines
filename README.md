# platform-pipelines

[![CI](https://github.com/Megjafari/platform-pipelines/actions/workflows/ci.yml/badge.svg)](https://github.com/Megjafari/platform-pipelines/actions/workflows/ci.yml)
[![Workflow tests](https://github.com/Megjafari/platform-pipelines/actions/workflows/workflow-tests.yml/badge.svg)](https://github.com/Megjafari/platform-pipelines/actions/workflows/workflow-tests.yml)
[![Release](https://img.shields.io/github/v/release/Megjafari/platform-pipelines)](https://github.com/Megjafari/platform-pipelines/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

A library of reusable CI/CD workflows. Instead of copying pipelines between
projects, a repository calls the workflow it needs and pins a version:

```yaml
jobs:
  ci:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-dotnet-ci.yml@v1
    with:
      dotnet-version: "10.0.x"
```

Fix something once here, and every consumer gets it by bumping the version.

See [how the pieces fit together](docs/architecture.md) and the
[documentation site](https://megjafari.github.io/platform-pipelines/).

## Catalog

| Workflow | Purpose |
| --- | --- |
| [`reusable-lint`](#reusable-lint) | actionlint, yamllint, gitleaks |
| [`reusable-dotnet-ci`](#reusable-dotnet-ci) | .NET build, test, coverage, format check |
| [`reusable-node-ci`](#reusable-node-ci) | npm / pnpm / yarn: lint, typecheck, test, build |
| [`reusable-container`](#reusable-container) | Multi-arch build, Trivy gate, SBOM, cosign, provenance, GHCR |
| [`reusable-container-promote`](#reusable-container-promote) | Promote a signed image by digest, without rebuilding |
| [`reusable-scheduled-scan`](#reusable-scheduled-scan) | Scan published images and track findings in issues |
| [`reusable-iac-validate`](#reusable-iac-validate) | Terraform, kubeconform, conftest policies |
| [`reusable-release`](#reusable-release) | Conventional Commits to release PR, tag and changelog |
| [`reusable-docs-site`](#reusable-docs-site) | MkDocs site on GitHub Pages |
| [`reusable-pr-checks`](#reusable-pr-checks) | PR title, description, size, labels |
| [`reusable-codeql`](#reusable-codeql) | Static security analysis |
| [`reusable-dependency-review`](#reusable-dependency-review) | Block vulnerable or badly licensed dependencies |
| [`reusable-lighthouse`](#reusable-lighthouse) | Performance and accessibility budgets |

### reusable-lint

Lints GitHub Actions workflows (actionlint), YAML (yamllint) and scans the git
history for secrets (gitleaks, checksum-verified install).

```yaml
jobs:
  lint:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-lint.yml@v1
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

### reusable-dotnet-ci

Restores, checks formatting, builds and tests, and uploads test results and
coverage (Cobertura) as artifacts. Test projects need the `coverlet.collector`
package for coverage. Can also publish a project as an artifact.

```yaml
jobs:
  dotnet:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-dotnet-ci.yml@v1
    with:
      dotnet-version: "10.0.x"
      working-directory: src
```

| Input | Default | Description |
| --- | --- | --- |
| `dotnet-version` | `10.0.x` | .NET SDK version |
| `working-directory` | `.` | Directory with the solution or project |
| `configuration` | `Release` | Build configuration |
| `run-format` | `true` | Fail if `dotnet format` would change anything |
| `publish-project` | empty | Project to publish as an artifact, relative to `working-directory` |

### reusable-container

Scans the build context, builds a local image and scans that too. Only if both
pass does it build for all platforms and push to GHCR. After the push it creates
an SPDX SBOM, signs with cosign (keyless) and adds GitHub attestations, all on the
digest, and then verifies the result. Pull requests build and scan but never push. The base image is pulled on every
build, and the layer cache starts over each day, so a `RUN apk upgrade` or
similar step is never more than a day old.

```yaml
jobs:
  container:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-container.yml@v1
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
| `no-cache` | `false` | Build without the layer cache, to force upgrades in `RUN` steps |
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

### reusable-node-ci

Installs from the lockfile and runs the project's `lint`, `typecheck`, `test` and
`build` scripts. A script missing from `package.json` is skipped. pnpm and yarn
run through corepack, so set `packageManager` in `package.json`.

```yaml
jobs:
  node:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-node-ci.yml@v1
    with:
      package-manager: pnpm
      build-output: dist
```

| Input | Default | Description |
| --- | --- | --- |
| `node-version` | `24` | Node.js version |
| `package-manager` | `npm` | `npm`, `pnpm` or `yarn` |
| `working-directory` | `.` | Directory with `package.json` |
| `run-lint`, `run-typecheck`, `run-test`, `run-build` | `true` | Turn a step off |
| `build-output` | empty | Output to upload as an artifact |

### reusable-container-promote

Adds a tag such as `staging` or `prod` to an image that is already built. It verifies
that the digest was signed by `reusable-container`, adds the tag and confirms the
result. Nothing is rebuilt, so what was tested is what moves on. Use a GitHub
environment with required reviewers for manual approval.

```yaml
jobs:
  promote:
    needs: container
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-container-promote.yml@v1
    permissions:
      contents: read
      packages: write
    with:
      image: ${{ needs.container.outputs.image }}
      digest: ${{ needs.container.outputs.digest }}
      target-tag: prod
      environment: prod
```

| Input | Default | Description |
| --- | --- | --- |
| `image` | required | Image name without tag or digest |
| `digest` | required | Digest to promote |
| `target-tag` | required | Tag to add |
| `environment` | empty | GitHub environment for the job |
| `signed-by-repository` | calling repository | Repository that must have signed the image |
| `crane-version` | `0.22.1` | Pinned tool version |

### reusable-scheduled-scan

An image that was clean when it was built can have known vulnerabilities later.
This scans published images on a schedule and keeps one issue per image up to date,
closing it when the image is clean. A scan that cannot run fails the job.

```yaml
on:
  schedule:
    - cron: "23 3 * * *"

jobs:
  scan:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-scheduled-scan.yml@v1
    permissions:
      contents: read
      issues: write
      packages: read
    with:
      images: |
        ghcr.io/owner/app:prod
        ghcr.io/owner/worker:prod
```

| Input | Default | Description |
| --- | --- | --- |
| `images` | required | Image references, one per line |
| `severity` | `CRITICAL,HIGH` | Severities to report |
| `ignore-unfixed` | `true` | Ignore vulnerabilities without a fix |
| `open-issues` | `true` | Open, update and close issues |
| `fail-on-findings` | `false` | Fail the job when there are findings |
| `issue-label` | `vulnerability-scan` | Label on the issues |
| `trivy-version` | `0.76.2` | Pinned tool version |

### reusable-iac-validate

Each part runs only when its directory is set, and none of them need credentials
or remote state. `conftest verify` runs the policies' own unit tests, and
`conftest test` applies them to the manifests. The policies live in the calling
repository; [`policies/`](policies) is an example.

```yaml
jobs:
  iac:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-iac-validate.yml@v1
    with:
      terraform-directory: terraform
      kubernetes-directory: k8s
      policy-directory: policies
```

| Input | Default | Description |
| --- | --- | --- |
| `terraform-directory` | empty | fmt, validate and tflint |
| `kubernetes-directory` | empty | kubeconform |
| `policy-directory` | empty | conftest |
| `terraform-version` | `latest` | Terraform version |
| `tflint-version`, `kubeconform-version`, `conftest-version` | see workflow | Pinned tool versions |

### reusable-release

release-please turns Conventional Commits into a release PR with a changelog, and
merging that PR creates the tag and GitHub release. Needs
`release-please-config.json`, `.release-please-manifest.json` and the repository
setting *Allow GitHub Actions to create and approve pull requests*.

```yaml
jobs:
  release:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-release.yml@v1
    permissions:
      contents: write
      pull-requests: write
    with:
      update-major-tag: true
```

| Input | Default | Description |
| --- | --- | --- |
| `update-major-tag` | `false` | Move the floating major tag (`v1`) to each release |

Outputs: `release-created` and `tag-name`.

### reusable-docs-site

Builds a MkDocs Material site in strict mode, so broken links fail the build, and
can deploy it to GitHub Pages. Set Pages to *GitHub Actions* in the repository
settings first.

```yaml
jobs:
  docs:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-docs-site.yml@v1
    permissions:
      contents: read
      pages: write
      id-token: write
    with:
      deploy: ${{ github.ref == 'refs/heads/main' }}
```

| Input | Default | Description |
| --- | --- | --- |
| `working-directory` | `.` | Directory with `mkdocs.yml` |
| `deploy` | `false` | Deploy to GitHub Pages |
| `python-version`, `mkdocs-material-version` | see workflow | Pinned tool versions |

### reusable-pr-checks

The PR title must follow Conventional Commits and the description must not be
empty. Large PRs get a warning, and the PR is labeled with its commit type. Call it
from a `pull_request` event with `types: [opened, edited, synchronize, reopened]`,
so that editing the title runs it again.

```yaml
jobs:
  pr-checks:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-pr-checks.yml@v1
    permissions:
      contents: read
      issues: write
      pull-requests: write
```

| Input | Default | Description |
| --- | --- | --- |
| `types` | `feat\|fix\|docs\|chore\|ci\|refactor\|test\|build\|perf\|revert` | Allowed commit types |
| `max-changed-lines` | `500` | Warn above this size |
| `label` | `true` | Label the PR with its commit type |

### reusable-codeql

Static security analysis without a build step. Results appear under the Security
tab. Every language in the list needs source code in the repository.

```yaml
jobs:
  codeql:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-codeql.yml@v1
    permissions:
      actions: read
      contents: read
      packages: read
      security-events: write
    with:
      languages: '["csharp", "javascript-typescript"]'
```

| Input | Default | Description |
| --- | --- | --- |
| `languages` | `["csharp", "javascript-typescript"]` | JSON list of languages |
| `queries` | `security-extended` | Query suite |

### reusable-dependency-review

Blocks PRs that add dependencies with known vulnerabilities or denied licenses.
Call it from a `pull_request` event. The repository needs the dependency graph
turned on.

```yaml
jobs:
  dependency-review:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-dependency-review.yml@v1
    permissions:
      contents: read
      pull-requests: write
```

| Input | Default | Description |
| --- | --- | --- |
| `fail-on-severity` | `high` | Lowest severity that fails the check |
| `deny-licenses` | `AGPL-3.0-only, AGPL-3.0-or-later` | Licenses to block |
| `comment-summary` | `on-failure` | When to comment on the PR |

### reusable-lighthouse

Fails when a Lighthouse category drops below its budget. Works on a built site or
a deployed URL, and uses the median of several runs because scores vary a little.
Scores go to the job summary and full reports are uploaded as artifacts.

```yaml
jobs:
  lighthouse:
    uses: Megjafari/platform-pipelines/.github/workflows/reusable-lighthouse.yml@v1
    with:
      static-dir: dist
      min-performance: 0.8
```

| Input | Default | Description |
| --- | --- | --- |
| `static-dir` | empty | Built site, relative to the repository root |
| `url` | empty | Deployed site, used when `static-dir` is empty |
| `runs` | `3` | Runs per page |
| `min-performance`, `min-accessibility`, `min-best-practices`, `min-seo` | `0.9` | Budgets from 0 to 1 |

## Versions

Pin `@v1` to get fixes automatically, or an exact tag such as `@v1.0.0` for full
control. Breaking changes get a new major version. Releases are listed on the
[releases page](https://github.com/Megjafari/platform-pipelines/releases).

## How this repository tests itself

- `ci*.yml`, `docs.yml` and `pr-checks.yml` call the workflows through local paths,
  so a pull request tests its own changes.
- [`consumer-demo.yml`](.github/workflows/consumer-demo.yml) calls the library at
  `@v1`, the way another repository would.
- [`workflow-tests.yml`](.github/workflows/workflow-tests.yml) proves that the
  security gates stop what they should stop.

## Repository layout

```
.github/workflows/   workflows (reusable-*.yml are the library, the rest is this repo's own CI)
examples/            small apps the workflows are tested against
policies/            Rego policies used by conftest
docs/                architecture notes and ADRs
```

## Development

Linting runs through Docker, so nothing else needs to be installed:

```bash
make lint
```

## Principles

- **Least privilege:** every workflow declares its own minimal `permissions:`.
- **Pinned and updated:** actions are pinned to digests and kept current by Renovate.
- **Tested:** workflows are linted, and security gates have negative tests.
- **Decisions are written down:** see [docs/adr](docs/adr).

## License

[MIT](LICENSE)
