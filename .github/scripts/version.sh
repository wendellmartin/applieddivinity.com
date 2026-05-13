#!/bin/bash
source .github/scripts/utils.sh

current_version="$(get_version)"
echo "Current version: $current_version"

IFS='.' read -ra VERSION <<< "$current_version"

echo "Current version: $current_version"

case $1 in
  major)
    echo "Bumping major version"
    VERSION[0]=$((VERSION[0] + 1))
    VERSION[1]=0
    VERSION[2]=0
    echo "New version: ${VERSION[0]}.${VERSION[1]}.${VERSION[2]}"
    ;;
  minor)
    echo "Bumping minor version"
    VERSION[1]=$((VERSION[1] + 1))
    VERSION[2]=0
    echo "New version: ${VERSION[0]}.${VERSION[1]}.${VERSION[2]}"
    ;;
  patch|auto)
    echo "Bumping patch version"
    VERSION[2]=$((VERSION[2] + 1))
    echo "New version: ${VERSION[0]}.${VERSION[1]}.${VERSION[2]}"
    ;;
  *)
    echo "Invalid type: $1. Use major/minor/patch/auto"
    exit 1
    ;;
esac

new_version="${VERSION[0]}.${VERSION[1]}.${VERSION[2]}"
update_version "$new_version"
create_tag "$new_version"
create_artifact "$new_version"