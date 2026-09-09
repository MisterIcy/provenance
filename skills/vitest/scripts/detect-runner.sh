#!/usr/bin/env bash
# Detects how to invoke Vitest in the current project: package manager,
# whether Vitest is a direct devDependency, and any workspace/projects config.
# Prints a short report to stdout. Always exits 0 (informational only) unless
# no project root markers are found at all.
set -euo pipefail

root="${1:-.}"
pkg_json="$root/package.json"

if [ ! -f "$pkg_json" ]; then
  echo "No package.json found under '$root' — not a Node/TS project root." >&2
  exit 1
fi

pm="npm"
if [ -f "$root/pnpm-lock.yaml" ]; then
  pm="pnpm"
elif [ -f "$root/yarn.lock" ]; then
  pm="yarn"
elif [ -f "$root/bun.lockb" ] || [ -f "$root/bun.lock" ]; then
  pm="bun"
elif [ -f "$root/package-lock.json" ]; then
  pm="npm"
fi

case "$pm" in
  npm) runner="npx vitest" ;;
  pnpm) runner="pnpm vitest" ;;
  yarn) runner="yarn vitest" ;;
  bun) runner="bun run vitest" ;;
esac

echo "package manager: $pm"
echo "suggested invocation: $runner"

has_vitest_dep=$(grep -c '"vitest"' "$pkg_json" 2>/dev/null || true)
if [ "${has_vitest_dep:-0}" -gt 0 ]; then
  echo "vitest: declared in package.json"
else
  echo "vitest: not found in package.json dependencies (check a shared/root package.json in a monorepo)"
fi

configs=$(find "$root" -maxdepth 2 \( -name "vitest.config.*" -o -name "vitest.workspace.*" -o -name "vitest.projects.*" \) 2>/dev/null || true)
if [ -n "$configs" ]; then
  echo "config files found:"
  echo "$configs" | sed 's/^/  /'
else
  echo "no vitest.config.*/vitest.workspace.*/vitest.projects.* found at depth <=2 — check vite.config.* for a 'test' field, or search deeper for a monorepo layout"
fi
