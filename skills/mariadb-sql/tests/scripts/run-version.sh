#!/usr/bin/env bash
#
# run-version.sh <version> [--keep]
#
# Boots the mariadb-sql test harness's Docker Compose service for one
# MariaDB milestone version, applies the baseline schema plus any cumulative
# fixture deltas up to that version, runs the tagged content-verification
# cases, prints a PASS/FAIL summary, and tears the container down again
# (unless --keep is passed).
#
# Usage:
#   scripts/run-version.sh 10.2            # from the tests/ directory
#   skills/mariadb-sql/tests/scripts/run-version.sh 10.2   # from repo root
#   scripts/run-version.sh 10.2 --keep     # leave the container running after
#
# Exit code is non-zero if the container never becomes healthy, the schema
# fails to apply, or any content-verification case fails.
set -uo pipefail

# ---------------------------------------------------------------------------
# Resolve paths so this works regardless of invocation cwd.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TESTS_DIR="$(cd -- "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
COMPOSE_FILE="${TESTS_DIR}/docker/docker-compose.yml"
FIXTURES_DIR="${TESTS_DIR}/fixtures"
CONTENT_CASES_DIR="${TESTS_DIR}/cases/content"

# Ordered oldest -> newest. Used to resolve "versions <= requested" for both
# cumulative fixture deltas and version-tagged content cases.
ALL_VERSIONS=(10.2 10.3 10.4 10.5 10.6 10.11 11.4 11.8 12.3)

ROOT_PASSWORD="test_root_password"
DB_NAME="skilltest"

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
VERSION="${1:-}"
KEEP=0
for arg in "$@"; do
    case "$arg" in
        --keep) KEEP=1 ;;
    esac
done

usage() {
    cat <<EOF
Usage: $(basename "$0") <version> [--keep]

  <version>  One of: ${ALL_VERSIONS[*]}
  --keep     Leave the container running after the run (skip teardown).

Examples:
  $(basename "$0") 10.2
  $(basename "$0") 10.2 --keep
EOF
}

if [[ -z "$VERSION" || "$VERSION" == "-h" || "$VERSION" == "--help" ]]; then
    usage
    exit 2
fi

# Validate version is known and find its index for "<=" comparisons.
VERSION_INDEX=-1
for i in "${!ALL_VERSIONS[@]}"; do
    if [[ "${ALL_VERSIONS[$i]}" == "$VERSION" ]]; then
        VERSION_INDEX=$i
        break
    fi
done
if [[ $VERSION_INDEX -eq -1 ]]; then
    echo "ERROR: unknown version '${VERSION}'. Known versions: ${ALL_VERSIONS[*]}" >&2
    exit 2
fi

SERVICE="mariadb-${VERSION}"

# Map version -> host port (must match docker-compose.yml).
declare -A PORT_MAP=(
    ["10.2"]=13302
    ["10.3"]=13303
    ["10.4"]=13304
    ["10.5"]=13305
    ["10.6"]=13306
    ["10.11"]=13311
    ["11.4"]=13404
    ["11.8"]=13408
    ["12.3"]=13503
)
HOST_PORT="${PORT_MAP[$VERSION]}"

# We exec the SQL client that ships INSIDE the container via
# `docker compose exec`, rather than requiring a host-installed mysql/mariadb
# client. This keeps the harness portable across machines that don't have a
# client on PATH, and sidesteps auth-plugin differences across versions
# (e.g. pre-10.4 images have no unix-socket auth for root@localhost, so a
# host-side client would need TCP + password anyway). HOST_PORT is still
# mapped in docker-compose.yml for optional manual/external debugging.
#
# The client binary name is version-dependent: images through ~11.x ship
# `mysql` (with `mariadb` as an alias); 12.3+ dropped the mysql* compat
# binaries entirely and only ships `mariadb`. Resolve whichever exists in
# the target container rather than hardcoding one name.
run_sql() {
    # run_sql < file.sql   -- reads SQL from stdin
    docker compose --profile "$VERSION" -f "$COMPOSE_FILE" exec -T "$SERVICE" \
        sh -c 'client=$(command -v mariadb || command -v mysql); exec "$client" --user=root --password="$1" --database="$2"' \
        _ "$ROOT_PASSWORD" "$DB_NAME"
}

PASS_COUNT=0
FAIL_COUNT=0
FAIL_NAMES=()

cleanup() {
    if [[ "$KEEP" -eq 1 ]]; then
        echo "--keep passed: leaving '${SERVICE}' running on port ${HOST_PORT}."
        return
    fi
    echo "Tearing down '${SERVICE}'..."
    docker compose --profile "$VERSION" -f "$COMPOSE_FILE" down >/dev/null 2>&1
}
trap cleanup EXIT

echo "=== mariadb-sql test harness: version ${VERSION} ==="
echo "Compose file: ${COMPOSE_FILE}"
echo "Service:      ${SERVICE}"
echo "Host port:    ${HOST_PORT}"
echo

# ---------------------------------------------------------------------------
# 1. Boot the service.
# ---------------------------------------------------------------------------
echo "--- Starting container ---"
if ! docker compose --profile "$VERSION" -f "$COMPOSE_FILE" up -d "$SERVICE"; then
    echo "FAIL: docker compose up failed for ${SERVICE}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. Wait for healthy.
# ---------------------------------------------------------------------------
echo "--- Waiting for healthy ---"
CONTAINER_ID="$(docker compose --profile "$VERSION" -f "$COMPOSE_FILE" ps -q "$SERVICE")"
if [[ -z "$CONTAINER_ID" ]]; then
    echo "FAIL: could not resolve container id for ${SERVICE}" >&2
    exit 1
fi

TIMEOUT_SECONDS=120
ELAPSED=0
POLL_INTERVAL=2
HEALTHY=0
while [[ $ELAPSED -lt $TIMEOUT_SECONDS ]]; do
    STATUS="$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_ID" 2>/dev/null || echo "unknown")"
    if [[ "$STATUS" == "healthy" ]]; then
        HEALTHY=1
        break
    fi
    sleep "$POLL_INTERVAL"
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

if [[ "$HEALTHY" -ne 1 ]]; then
    echo "FAIL: ${SERVICE} did not become healthy within ${TIMEOUT_SECONDS}s (last status: ${STATUS})" >&2
    docker logs "$CONTAINER_ID" 2>&1 | tail -n 50 >&2
    exit 1
fi
echo "Container healthy after ~${ELAPSED}s."
echo

# ---------------------------------------------------------------------------
# 3. Apply baseline schema + cumulative deltas <= requested version.
# ---------------------------------------------------------------------------
echo "--- Applying schema ---"

# Baseline always applies first.
BASELINE="${FIXTURES_DIR}/00-baseline-schema.sql"
if [[ ! -f "$BASELINE" ]]; then
    echo "FAIL: baseline fixture missing: ${BASELINE}" >&2
    exit 1
fi
if ! run_sql < "$BASELINE"; then
    echo "FAIL: applying ${BASELINE} failed" >&2
    exit 1
fi
echo "Applied $(basename "$BASELINE")."

# Cumulative deltas: fixtures/<version>-delta.sql for every version <= requested,
# in oldest->newest order (skipping "00-baseline-schema" itself, which is
# handled above). For now no delta files exist yet -- this loop is a no-op
# until later agents add fixtures/<version>-delta.sql files.
for (( i=0; i<=VERSION_INDEX; i++ )); do
    v="${ALL_VERSIONS[$i]}"
    delta_file="${FIXTURES_DIR}/${v}-delta.sql"
    if [[ -f "$delta_file" ]]; then
        if ! run_sql < "$delta_file"; then
            echo "FAIL: applying ${delta_file} failed" >&2
            exit 1
        fi
        echo "Applied $(basename "$delta_file")."
    fi
done
echo

# ---------------------------------------------------------------------------
# 4. Run content-verification cases <= requested version.
# ---------------------------------------------------------------------------
#
# Convention (see tests/README.md for the full writeup):
#   cases/content/<name>.sql          -- the query/statement(s) to run
#   cases/content/<name>.expected     -- line 1: expected exit code
#                                        remaining lines: a substring that
#                                        must appear somewhere in stdout
#   cases/content/<name>.version      -- optional, single line, one of
#                                        ALL_VERSIONS; the MINIMUM version
#                                        this case applies to. A case with no
#                                        .version file is treated as applying
#                                        to every version (10.2+).
#
# A case only runs if its tagged minimum version is <= the version this
# script was invoked with.
echo "--- Running content-verification cases ---"

if [[ -d "$CONTENT_CASES_DIR" ]] && compgen -G "${CONTENT_CASES_DIR}/*.sql" >/dev/null 2>&1; then
    for sql_file in "$CONTENT_CASES_DIR"/*.sql; do
        name="$(basename "$sql_file" .sql)"
        expected_file="${CONTENT_CASES_DIR}/${name}.expected"
        version_file="${CONTENT_CASES_DIR}/${name}.version"

        min_version="10.2"
        if [[ -f "$version_file" ]]; then
            min_version="$(tr -d '[:space:]' < "$version_file")"
        fi

        min_index=-1
        for i in "${!ALL_VERSIONS[@]}"; do
            if [[ "${ALL_VERSIONS[$i]}" == "$min_version" ]]; then
                min_index=$i
                break
            fi
        done
        if [[ $min_index -eq -1 ]]; then
            echo "SKIP: ${name} has unknown .version '${min_version}'"
            continue
        fi
        if [[ $min_index -gt $VERSION_INDEX ]]; then
            echo "SKIP: ${name} requires >= ${min_version}, running ${VERSION}"
            continue
        fi

        if [[ ! -f "$expected_file" ]]; then
            echo "FAIL: ${name} has no companion .expected file"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            FAIL_NAMES+=("$name")
            continue
        fi

        expected_exit="$(sed -n '1p' "$expected_file" | tr -d '[:space:]')"
        expected_pattern="$(tail -n +2 "$expected_file")"

        actual_output="$(run_sql < "$sql_file" 2>&1)"
        actual_exit=$?

        ok=1
        if [[ "$actual_exit" != "$expected_exit" ]]; then
            ok=0
        fi
        if [[ -n "$expected_pattern" ]] && ! grep -qF "$expected_pattern" <<< "$actual_output"; then
            ok=0
        fi

        if [[ "$ok" -eq 1 ]]; then
            echo "PASS: ${name}"
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            echo "FAIL: ${name} (expected exit=${expected_exit}, got exit=${actual_exit})"
            echo "  --- actual output ---"
            echo "$actual_output" | sed 's/^/  /'
            FAIL_COUNT=$((FAIL_COUNT + 1))
            FAIL_NAMES+=("$name")
        fi
    done
else
    echo "(no content-verification cases found under ${CONTENT_CASES_DIR} -- skipping)"
fi
echo

# ---------------------------------------------------------------------------
# 5. Summary.
# ---------------------------------------------------------------------------
echo "=== Summary for ${VERSION} ==="
echo "Passed: ${PASS_COUNT}"
echo "Failed: ${FAIL_COUNT}"
if [[ "$FAIL_COUNT" -gt 0 ]]; then
    echo "Failing cases: ${FAIL_NAMES[*]}"
    echo "RESULT: FAIL"
    exit 1
fi
echo "RESULT: PASS"
exit 0
