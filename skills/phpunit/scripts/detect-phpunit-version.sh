#!/usr/bin/env bash
# Detects the PHPUnit major version in use by the current PHP project.
# Prints a single major version number (9-13) to stdout on success.
# Exits non-zero with a diagnostic on stderr if no version could be determined.
set -euo pipefail

root="${1:-.}"
lock="$root/composer.lock"
composer_json="$root/composer.json"

version_from_lock() {
  [ -f "$lock" ] || return 1
  if command -v php >/dev/null 2>&1; then
    php -r '
      $data = json_decode(file_get_contents($argv[1]), true);
      if (!is_array($data)) { exit(1); }
      foreach (array_merge($data["packages"] ?? [], $data["packages-dev"] ?? []) as $pkg) {
        if (($pkg["name"] ?? "") === "phpunit/phpunit") {
          echo $pkg["version"] ?? "";
          exit(0);
        }
      }
      exit(1);
    ' "$lock" 2>/dev/null && return 0
  fi
  grep -A2 '"name": *"phpunit/phpunit"' "$lock" 2>/dev/null \
    | grep -m1 '"version"' \
    | sed -E 's/.*"version": *"v?([0-9]+)\.[0-9]+\.[0-9]+.*/\1/' \
    || return 1
}

version_from_composer_json() {
  [ -f "$composer_json" ] || return 1
  if command -v php >/dev/null 2>&1; then
    php -r '
      $data = json_decode(file_get_contents($argv[1]), true);
      if (!is_array($data)) { exit(1); }
      $constraint = ($data["require-dev"]["phpunit/phpunit"] ?? null)
        ?? ($data["require"]["phpunit/phpunit"] ?? null);
      if ($constraint === null) { exit(1); }
      echo $constraint;
      exit(0);
    ' "$composer_json" 2>/dev/null && return 0
  fi
  grep -m1 '"phpunit/phpunit"' "$composer_json" 2>/dev/null \
    | sed -E 's/.*"phpunit\/phpunit": *"([^"]+)".*/\1/' \
    || return 1
}

version_from_binary() {
  local bin="$root/vendor/bin/phpunit"
  [ -x "$bin" ] || return 1
  "$bin" --version 2>/dev/null | grep -oE 'PHPUnit [0-9]+' | grep -oE '[0-9]+' || return 1
}

to_major() {
  # Accepts either a bare major ("11") or a constraint/version string
  # ("^10.5", "10.5.9", ">=9.6 <10") and extracts the first plausible major.
  grep -oE '[0-9]+' <<<"$1" | head -1
}

raw=""
for src in version_from_lock version_from_composer_json version_from_binary; do
  if raw=$("$src"); then
    [ -n "$raw" ] && break
  fi
  raw=""
done

if [ -z "$raw" ]; then
  echo "Could not determine phpunit/phpunit version: no composer.lock/composer.json entry and no vendor/bin/phpunit found under '$root'." >&2
  exit 1
fi

major=$(to_major "$raw")
if [ -z "$major" ]; then
  echo "Found a phpunit/phpunit version string ('$raw') but couldn't parse a major version from it." >&2
  exit 1
fi

echo "$major"
