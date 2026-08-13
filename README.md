![Latest Tag](https://img.shields.io/github/v/tag/pbaris/cicd-components?sort=semver)

# CI/CD Components

Public repository containing reusable **CI/CD components** for both **GitHub Actions** and **GitLab CI**.

The goal is to keep common logic (especially bash scripts) shared between platforms whenever possible.

---

## Components

### `get-next-version`

Computes the next Semantic Version[](https://semver.org/) based on Conventional Commits[](https://www.conventionalcommits.org/) since the last tag, and optionally creates + pushes a Git tag.

The core logic lives in a **shared bash script** (`scripts/get-next-version.sh`) and is used by both the GitHub Action and the GitLab CI template.

#### Features

- Detects the latest valid semver tag (`x.y.z`)
- Analyzes commit messages since that tag
- Determines the bump type:
    - **major** → `BREAKING CHANGE:` or commit type with `!` (e.g. `feat!:`, `fix!:`)
    - **minor** → `feat:` / `feat(...):`
    - **patch** → everything else
- Optionally creates and pushes an annotated Git tag
- Configurable tag prefix (default: none)

---

### GitHub Action

**Path:** `actions/get-next-version`

#### Inputs

| Input             | Required | Default               | Description                                              |
|-------------------|----------|-----------------------|----------------------------------------------------------|
| `default-version` | No       | `0.0.0`               | Version to start from when no previous tags exist        |
| `create-tag`      | No       | `true`                | Whether to create and push a Git tag                     |
| `tag-prefix`      | No       | `''`                  | Prefix to add to the tag (e.g. `v`)                      |
| `github-token`    | No       | `${{ github.token }}` | Token used to push the tag                               |

#### Outputs

| Output    | Description                                         |
|-----------|-----------------------------------------------------|
| `version` | Computed next version (e.g. `1.4.2`)                |
| `tag`     | Full tag name including prefix (e.g. `v1.4.2`)      |
| `major`   | Major part of the version                           |
| `minor`   | Minor part of the version                           |
| `patch`   | Patch part of the version                           |
| `bump`    | Type of bump applied (`major`, `minor`, or `patch`) |

#### Example usage

```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write # required to push tags

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get next version and create tag
        id: next
        uses: pbaris/cicd-components/.github/actions/get-next-version@main
        with:
          tag-prefix: 'v' # optional – default is no prefix

      - name: Print results
        run: |
          echo "Version : ${{ steps.next.outputs.version }}"
          echo "Tag     : ${{ steps.next.outputs.tag }}"
          echo "Bump    : ${{ steps.next.outputs.bump }}"
```

---

### GitLab CI Template

**Path:** `templates/get-next-version.yml`

#### Inputs

| Input             | Default              | Description                                       |
|-------------------|----------------------|---------------------------------------------------|
| `stage`           | `version`            | Stage in which the job will run                   |
| `create-tag`      | `"true"`             | Whether to create and push a Git tag              |
| `tag-prefix`      | `""`                 | Prefix to add to the tag (e.g. `v`)               |
| `default-version` | `"0.0.0"`            | Version to start from when no previous tags exist |
| `image`           | `bitnami/git:latest` | Container image used to run the job               |

#### Example usage

```yaml

include:
  - remote: 'https://raw.githubusercontent.com/pbaris/cicd-components/main/.gitlab/templates/get-next-version.yml'
    inputs:
      tag-prefix: "v"
      # stage: version
```

After the job runs, the following variables are available via `dotenv` report:

- `VERSION`
- `TAG`
- `MAJOR`
- `MINOR`
- `PATCH`
- `BUMP`

---

## Notes

- Always use full git history (`fetch-depth: 0` on GitHub / `GIT_DEPTH: 0` on GitLab) so the script can see all tags and commits.
- When creating tags, make sure the job has permission to push (GitHub: `contents: write`, GitLab: proper project permissions / token).
- Prefer pinning to a specific version tag (e.g. `@v1.0.0` or `/v1.0.0/`) instead of `main` for stability.
