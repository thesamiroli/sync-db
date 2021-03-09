#!/bin/bash

### Release management and changelog generation script. ###

set -e

printfln() {
  printf "\n$1\n"
}

changelog() {
  # NOTE: This requires github_changelog_generator to be installed.
  # https://github.com/skywinder/github-changelog-generator

  if [ -z "$NEXT" ]; then
      NEXT="Unreleased"
  fi

  echo "Generating changelog upto version: $NEXT"
  github_changelog_generator \
    --no-verbose \
    --pr-label "**Changes**" \
    --bugs-label "**Bug Fixes**" \
    --issues-label "**Closed Issues**" \
    --issue-line-labels=ALL \
    --future-release="$NEXT" \
    --release-branch=master \
    --exclude-labels=unnecessary,duplicate,question,invalid,wontfix
}

bump() {
  last_tag=$(git tag --sort=-creatordate | head -n 1)

  printfln "$last_tag"

  echo "Bumping the version: ${last_tag} -> ${NEXT}"
  NEXT="v${NEXT}"

  git tag "${NEXT}"
  hub release create "$NEXT" -m "$NEXT" || true
}

compare_and_release() {
  ## Compare the package.json file from two recent commits to master branch and export
  ## value to NEXT variable if it differs.

  # Get the second last commit from the master branch after merge.
  previous_commit_hash=$(git rev-parse @~)

  git fetch --all
  git checkout ${previous_commit_hash}

  old_version=$(cat package.json | jq -r ".version")

  printfln "Old package version: ${old_version}"

  git checkout master

  new_version=$(cat package.json | jq -r ".version")

  printfln "New package version: ${new_version}"

  NEXT=false

  if [ "$old_version" != "$new_version" ]; then
    printfln "Publishing changes to npm with version: ${new_version}"
    NEXT=${new_version}
  fi

  if [ -n "$NEXT" ] && [ "$NEXT" != "false" ]; then
    bump
  fi
}

# Run command received from args.
$1
