#!/usr/bin/env bash
# Re-pull every vendored skill from its upstream repo. Run from the repo root, then commit.
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
while read -r name repo path; do
  [ -z "$name" ] || [ "${name:0:1}" = "#" ] && continue
  d="$tmp/${repo//\//__}"
  [ -d "$d" ] || git clone --depth 1 -q "https://github.com/$repo" "$d"
  rm -rf "skills/$name"; cp -r "$d/$path" "skills/$name"
  [ -f "$d/LICENSE" ] && cp "$d/LICENSE" "skills/$name/LICENSE.upstream"
  echo "updated $name <- $repo/$path"
done < sources.txt
