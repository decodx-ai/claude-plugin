#!/usr/bin/env bash
# Normalize a release version to a tag: "0.0.1" -> "v0.0.1", "v0.0.1" / "V0.0.1" -> "v0.0.1".
# Prints the tag. Exits 1 when the version is not semantic versioning (MAJOR.MINOR.PATCH, with an
# optional pre-release like "-beta.1").
set -euo pipefail

raw="${1:-}"
raw="${raw#"${raw%%[![:space:]]*}"}" # trim leading whitespace
raw="${raw%"${raw##*[![:space:]]}"}" # trim trailing whitespace
version="${raw#[vV]}"

if [[ ! "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid version '${raw}'. Use MAJOR.MINOR.PATCH, for example 0.0.1 or v0.0.1." >&2
  exit 1
fi

echo "v${version}"
