# CI/CD Components

Repository containing reusable **GitHub Actions** and **Workflows**.

## Actions

### `get-next-version`

Computes the next [Semantic Version](https://semver.org/) based on [Conventional Commits](https://www.conventionalcommits.org/) since the last tag, and optionally creates + pushes a Git tag.

#### Features

- Detects the latest valid semver tag (`x.y.z`)
- Analyzes commit messages since that tag
- Determines the bump type:
    - **major** → `BREAKING CHANGE:` or commit type with `!` (e.g. `feat!:`, `fix!:`)
    - **minor** → `feat:` / `feat(...):`
    - **patch** → everything else
- Optionally creates and pushes an annotated Git tag
- Configurable tag prefix (default: none)

#### Inputs

| Input             | Required | Default               | Description                                                               |
|-------------------|----------|-----------------------|---------------------------------------------------------------------------|
| `default-version` | No       | `0.0.0`               | Version to start from when no previous semver tags exist                  |
| `create-tag`      | No       | `true`                | Whether to create and push a Git tag for the new version                  |
| `tag-prefix`      | No       | `''`                  | Prefix to add to the tag (e.g. `v` → `v1.2.3`). Leave empty for no prefix |
| `github-token`    | No       | `${{ github.token }}` | Token used to push the tag (only needed when `create-tag: true`)          |

#### Outputs

| Output    | Description                                         |
|-----------|-----------------------------------------------------|
| `version` | Computed next version (e.g. `1.4.2`)                |
| `tag`     | Full tag name including prefix (e.g. `1.4.2`)       |
| `major`   | Major part of the version                           |
| `minor`   | Minor part of the version                           |
| `patch`   | Patch part of the version                           |
| `bump`    | Type of bump applied (`major`, `minor`, or `patch`) |

#### Example usage

**Compute the next version and create a tag:**

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
        uses: pbaris/cicd-components/actions/get-next-version@main
        with:
          tag-prefix: 'v' # optional – default is no prefix

      - name: Print results
        run: |
          echo "Version : ${{ steps.next.outputs.version }}"
          echo "Tag     : ${{ steps.next.outputs.tag }}"
          echo "Bump    : ${{ steps.next.outputs.bump }}"
```
