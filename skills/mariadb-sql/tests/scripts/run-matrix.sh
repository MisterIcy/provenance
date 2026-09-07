#!/usr/bin/env bash
#
# run-matrix.sh
#
# Runs run-version.sh for every MariaDB milestone version in the harness,
# oldest -> newest, and prints an aggregated pass/fail table. Exits non-zero
# if any version failed.
#
# Usage:
#   scripts/run-matrix.sh              # from the tests/ directory
#   skills/mariadb-sql/tests/scripts/run-matrix.sh   # from repo root
#
# Versions with no fixtures/content-cases yet still "run" (schema-only), so
# this is safe to invoke before every version has real content -- it will
# not hide a real failure for a version that DOES have cases.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

ALL_VERSIONS=(10.2 10.3 10.4 10.5 10.6 10.11 11.4 11.8 12.3)

declare -A RESULT_MAP
declare -A PASS_MAP
declare -A FAIL_MAP
OVERALL_FAIL=0

echo "=== mariadb-sql test matrix: ${ALL_VERSIONS[*]} ==="
echo

for version in "${ALL_VERSIONS[@]}"; do
    echo "############################################################"
    echo "# Version: ${version}"
    echo "############################################################"

    OUTPUT_FILE="$(mktemp)"
    if "${SCRIPT_DIR}/run-version.sh" "$version" 2>&1 | tee "$OUTPUT_FILE"; then
        RESULT_MAP["$version"]="PASS"
    else
        RESULT_MAP["$version"]="FAIL"
        OVERALL_FAIL=1
    fi

    PASS_MAP["$version"]="$(grep -m1 '^Passed: ' "$OUTPUT_FILE" | grep -o '[0-9]*' || echo 0)"
    FAIL_MAP["$version"]="$(grep -m1 '^Failed: ' "$OUTPUT_FILE" | grep -o '[0-9]*' || echo 0)"
    rm -f "$OUTPUT_FILE"
    echo
done

echo "=== Matrix summary ==="
printf "%-10s %-8s %-8s %s\n" "VERSION" "PASSED" "FAILED" "RESULT"
for version in "${ALL_VERSIONS[@]}"; do
    printf "%-10s %-8s %-8s %s\n" "$version" "${PASS_MAP[$version]:-0}" "${FAIL_MAP[$version]:-0}" "${RESULT_MAP[$version]}"
done

if [[ "$OVERALL_FAIL" -ne 0 ]]; then
    echo
    echo "RESULT: at least one version FAILED"
    exit 1
fi

echo
echo "RESULT: all versions PASSED"
exit 0
