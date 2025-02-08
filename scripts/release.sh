#!/bin/sh
# Increments the project version (e.g. from 2.3.0 to 2.4.0)
# It handles stuff like
# * CHANGELOG
# * Package version
# * Git tags

# Credits for original version to Luca Ravizzotti

# Calculating the new version requires to know which kind of update this is
# The default version increment is patch
# Used values: major|minor|patch where in x.y.z :
# major=x
# minor=y
# patch=z

while getopts ":v:r:" arg; do
  case $arg in
  v) versionType=$OPTARG ;;
  r) releaseType=$OPTARG ;;
  *)
    printf "\n"
    printf "%s -v [none|patch|minor|major] -r [rc|rel] -d" "$0"
    printf "\n"
    printf "\n\t -v version type, default: none"
    printf "\n\t -r release type, default: rel"
    printf "\n\n"
    exit 0
    ;;
  esac
done

# Version type = none|patch|minor|major
if [ -z "$versionType" ]; then
  versionType="none"
fi
if [ "$versionType" != "none" ] && [ "$versionType" != "patch" ] && [ "$versionType" != "minor" ] && [ "$versionType" != "major" ]; then
  echo "Version type not supported, try with -h for help"
  exit 1
fi

# Release type = rc|rel
if [ -z "$releaseType" ] || [ "$releaseType" = "rel" ]; then
  releaseType=""
fi
if [ "$releaseType" != "" ] && [ "$releaseType" != "rc" ]; then
  echo "Release type not supported, try with -h for help"
  exit 1
fi

# Get current git branch name
branch=$(git rev-parse --abbrev-ref HEAD)

if [ "$branch" != "main" ]; then
  echo "Release can be done only on main branch"
  exit 1
fi

# Version bump only if needed
if [ "$versionType" != "none" ]; then
  if [ "$releaseType" = "" ]; then
    # Increment version without creating a tag and a commit (we will create them later)
    npm --no-git-tag-version version "$versionType" || exit 1
    cd 'projects/angular-email'
    npm --no-git-tag-version version "$versionType" || exit 1
    cd '../..'
  else
    # Increment version without creating a tag and a commit (we will create them later)
    npm --no-git-tag-version version "pre$versionType" --preid="$releaseType" || exit 1
    cd 'projects/angular-email'
    npm --no-git-tag-version version "pre$versionType" --preid="$releaseType" || exit 1
    cd '../..'
  fi
fi

# Always bump version for release candidates
if [ "$versionType" = "none" ] && [ "$releaseType" != "" ]; then
  # Increment version without creating a tag and a commit (we will create them later)
  npm --no-git-tag-version version pre --preid="$releaseType" || exit 1
  cd 'projects/angular-email'
  npm --no-git-tag-version version pre --preid="$releaseType" || exit 1
  cd '../..'
fi

# Using the package.json version
version="$(jq -r '.version' "$(dirname "$0")/../package.json")"

# changelog from tags only on release
if [ "$versionType" != "none" ] && [ "$releaseType" != "rc" ]; then
  rm CHANGELOG.md
  npm run changelog
  git add package.json package-lock.json projects/angular-email/package.json CHANGELOG.md
  git commit -m "chore(version): 💯 bump version to $version"
fi

# release candidate version commit
if [ "$releaseType" = "rc" ]; then
  rm CHANGELOG.md
  npm run changelog
  git add package.json package-lock.json projects/angular-email/package.json CHANGELOG.md
  git commit -m "chore(version): 🔜 release candidate version $version"
fi

if [ "$versionType" != "none" ] || [ "$releaseType" = "rc" ]; then
  # Gotta push them all
  git push
fi

