#!/usr/bin/env bash
set -euo pipefail

# Inputs (can be passed as env vars)
DEFAULT_VERSION="${DEFAULT_VERSION:-0.0.0}"
TAG_PREFIX="${TAG_PREFIX:-}"
CREATE_TAG="${CREATE_TAG:-false}"

git fetch --tags --force

LAST_TAG=""
# First try tags without prefix
for candidate in $(git tag -l '[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname); do
  if echo "$candidate" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    LAST_TAG="$candidate"
    break
  fi
done

# Also check for prefixed tags if prefix is set
if [[ -z "$LAST_TAG" && -n "$TAG_PREFIX" ]]; then
  for candidate in $(git tag -l "${TAG_PREFIX}[0-9]*.[0-9]*.[0-9]*" --sort=-v:refname); do
    version="${candidate#"$TAG_PREFIX"}"
    if echo "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      LAST_TAG="$version"
      break
    fi
  done
fi

LAST_TAG=${LAST_TAG:-$DEFAULT_VERSION}

if git rev-parse "${TAG_PREFIX}${LAST_TAG}" >/dev/null 2>&1; then
  COMMITS=$(git log --format='%s%n%b' "${TAG_PREFIX}${LAST_TAG}..HEAD")
elif git rev-parse "$LAST_TAG" >/dev/null 2>&1; then
  COMMITS=$(git log --format='%s%n%b' "${LAST_TAG}..HEAD")
else
  COMMITS=$(git log --format='%s%n%b')
fi

# --- Conventional Commits bump rules ---
BUMP="patch"
if echo "$COMMITS" | grep -Eq '^BREAKING[ -]CHANGE:'; then
  BUMP="major"
elif echo "$COMMITS" | grep -Eiq '^[a-z]+(\(.+\))?!:'; then
  BUMP="major"
elif echo "$COMMITS" | grep -Eiq '^feat(\(.+\))?:'; then
  BUMP="minor"
fi
# ---------------------------------------

IFS='.' read -r MAJOR MINOR REVISION <<< "$LAST_TAG"
MAJOR=${MAJOR:-0}
MINOR=${MINOR:-0}
REVISION=${REVISION:-0}

case "$BUMP" in
  major) MAJOR=$((10#$MAJOR + 1)); MINOR=0; REVISION=0 ;;
  minor) MINOR=$((10#$MINOR + 1)); REVISION=0 ;;
  patch) REVISION=$((10#$REVISION + 1)) ;;
esac

SEMVER="${MAJOR}.${MINOR}.${REVISION}"
FULL_TAG="${TAG_PREFIX}${SEMVER}"

echo "Computed semver: ${SEMVER} (bump: ${BUMP})"

# Export results
echo "VERSION=${SEMVER}"
echo "TAG=${FULL_TAG}"
echo "MAJOR=${MAJOR}"
echo "MINOR=${MINOR}"
echo "PATCH=${REVISION}"
echo "BUMP=${BUMP}"

# Optionally create tag
if [[ "$CREATE_TAG" == "true" ]]; then
  echo "Creating and pushing tag: ${FULL_TAG}"

  git config user.name "${GIT_USER_NAME:-github-actions[bot]}"
  git config user.email "${GIT_USER_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"

  git tag -a "$FULL_TAG" -m "Release ${FULL_TAG}"
  git push origin "$FULL_TAG"
fi
