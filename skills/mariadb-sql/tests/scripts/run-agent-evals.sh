#!/usr/bin/env bash
#
# run-agent-evals.sh
#
# Prepares and grades agent-eval cases from cases/agent-evals/evals.json
# against the sql-query-reviewer subagent.
#
# IMPORTANT — what this script can and cannot do:
#   A plain bash script has no way to invoke the Claude Code Agent/Task tool
#   (that's a capability of a running Claude Code session, not a shell
#   primitive). So this script cannot itself send a case's prompt to the
#   sql-query-reviewer subagent and cannot itself judge free-text semantic
#   assertions like "response identifies the target version as 10.4". Those
#   assertions require a human, or a Claude Code session acting as grader,
#   to read the subagent's actual output and judge it.
#
#   What this script DOES do mechanically:
#     - Boot the right MariaDB version's container and apply fixtures
#       (via run-version.sh --keep), so a live-mode review actually has a
#       real database to connect to.
#     - Resolve and print one case's prompt, target version, DB connection
#       info, and assertions, in a format ready to hand to a subagent
#       invocation.
#     - Grade a previously-captured subagent response: for each assertion,
#       run a best-effort keyword/pattern check (a weak, mechanical signal
#       only) AND accept a human/agent-supplied verdict via --verdicts,
#       then aggregate into a pass/fail. It never invents a verdict for an
#       assertion nobody actually judged.
#     - Tear the container down afterwards (unless --keep).
#
# Usage:
#   scripts/run-agent-evals.sh prepare <id>              # boot + print one case's prompt
#   scripts/run-agent-evals.sh prepare <id> --keep        # ...and leave container running
#   scripts/run-agent-evals.sh list                       # list all case ids + versions
#   scripts/run-agent-evals.sh grade <id> --response <file> [--verdicts "1=pass,2=fail,..."]
#
# `grade`'s --verdicts takes a comma-separated list of <assertion-index>=<pass|fail>
# (1-based, matching the order assertions are printed in). Any assertion index
# not covered by --verdicts is reported as NEEDS-HUMAN-JUDGMENT, not silently
# passed. Overall case verdict is PASS only if every assertion has a verdict
# and all are "pass".
#
# There is no "run all cases end-to-end" mode here, because "end-to-end"
# requires a live subagent invocation this script cannot perform. See
# README.md for the actual workflow: a Claude Code session runs `prepare`
# per case, invokes sql-query-reviewer itself with the printed prompt (and
# DB connection info if the case needs a live check), then runs `grade` with
# its own judged --verdicts.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TESTS_DIR="$(cd -- "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
EVALS_FILE="${TESTS_DIR}/cases/agent-evals/evals.json"

ROOT_PASSWORD="test_root_password"
DB_NAME="skilltest"

declare -A PORT_MAP=(
    ["10.2"]=13302 ["10.3"]=13303 ["10.4"]=13304 ["10.5"]=13305
    ["10.6"]=13306 ["10.11"]=13311 ["11.4"]=13404 ["11.8"]=13408 ["12.3"]=13503
)

if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required to parse ${EVALS_FILE}" >&2
    exit 2
fi
if [[ ! -f "$EVALS_FILE" ]]; then
    echo "ERROR: evals file not found: ${EVALS_FILE}" >&2
    exit 2
fi

usage() {
    cat <<EOF
Usage:
  $(basename "$0") list
  $(basename "$0") prepare <id> [--keep]
  $(basename "$0") grade <id> --response <file> [--verdicts "1=pass,2=fail,..."]
EOF
}

CMD="${1:-}"
shift || true

case "$CMD" in
    list)
        jq -r '.evals[] | "\(.id)\t\(.target_version)\t\(.prompt[0:80])"' "$EVALS_FILE" \
            | awk -F'\t' '{printf "%-4s %-8s %s\n", $1, $2, $3}'
        exit 0
        ;;

    prepare)
        ID="${1:-}"
        shift || true
        KEEP=0
        for arg in "$@"; do
            [[ "$arg" == "--keep" ]] && KEEP=1
        done
        if [[ -z "$ID" ]]; then
            usage
            exit 2
        fi

        CASE_JSON="$(jq -c --argjson id "$ID" '.evals[] | select(.id == $id)' "$EVALS_FILE")"
        if [[ -z "$CASE_JSON" ]]; then
            echo "ERROR: no case with id ${ID} in ${EVALS_FILE}" >&2
            exit 2
        fi

        VERSION="$(jq -r '.target_version' <<< "$CASE_JSON")"
        PROMPT="$(jq -r '.prompt' <<< "$CASE_JSON")"

        if [[ -z "${PORT_MAP[$VERSION]+x}" ]]; then
            echo "ERROR: case ${ID} names unknown target_version '${VERSION}'" >&2
            exit 2
        fi
        HOST_PORT="${PORT_MAP[$VERSION]}"

        echo "--- Booting version ${VERSION} for eval case ${ID} ---"
        RUN_ARGS=("$VERSION" --keep)
        if ! "${SCRIPT_DIR}/run-version.sh" "${RUN_ARGS[@]}"; then
            echo "ERROR: run-version.sh failed to boot/verify ${VERSION}; see output above" >&2
            exit 1
        fi
        echo

        echo "================================================================"
        echo "EVAL CASE BUNDLE — id ${ID}"
        echo "================================================================"
        echo "Target version: ${VERSION}"
        echo
        echo "--- Prompt to send to the sql-query-reviewer subagent verbatim ---"
        echo "$PROMPT"
        echo
        echo "--- Live DB connection (if the prompt/case calls for a live check) ---"
        echo "Host: 127.0.0.1"
        echo "Port: ${HOST_PORT}"
        echo "User: root"
        echo "Password: ${ROOT_PASSWORD}"
        echo "Database: ${DB_NAME}"
        echo "Client (inside container): docker compose --profile ${VERSION} -f ${TESTS_DIR}/docker/docker-compose.yml exec -T mariadb-${VERSION} sh -c 'client=\$(command -v mariadb || command -v mysql); \"\$client\" --user=root --password=${ROOT_PASSWORD} --database=${DB_NAME}'"
        echo
        echo "--- Assertions to grade the subagent's response against ---"
        jq -r '.assertions[] | "  - " + .' <<< "$CASE_JSON"
        echo
        echo "--- Expected output (reference only — do not leak to the subagent) ---"
        jq -r '.expected_output' <<< "$CASE_JSON"
        echo "================================================================"
        echo
        if [[ "$KEEP" -eq 1 ]]; then
            echo "Container left running (--keep). Tear it down with:"
            echo "  docker compose --profile ${VERSION} -f ${TESTS_DIR}/docker/docker-compose.yml down"
        else
            echo "--- Tearing down ${VERSION} ---"
            docker compose --profile "$VERSION" -f "${TESTS_DIR}/docker/docker-compose.yml" down >/dev/null 2>&1
        fi
        exit 0
        ;;

    grade)
        ID="${1:-}"
        shift || true
        RESPONSE_FILE=""
        VERDICTS=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --response) RESPONSE_FILE="$2"; shift 2 ;;
                --verdicts) VERDICTS="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        if [[ -z "$ID" || -z "$RESPONSE_FILE" ]]; then
            usage
            exit 2
        fi
        if [[ ! -f "$RESPONSE_FILE" ]]; then
            echo "ERROR: response file not found: ${RESPONSE_FILE}" >&2
            exit 2
        fi

        CASE_JSON="$(jq -c --argjson id "$ID" '.evals[] | select(.id == $id)' "$EVALS_FILE")"
        if [[ -z "$CASE_JSON" ]]; then
            echo "ERROR: no case with id ${ID} in ${EVALS_FILE}" >&2
            exit 2
        fi

        # Parse --verdicts "1=pass,2=fail" into an associative array.
        declare -A VERDICT_MAP
        if [[ -n "$VERDICTS" ]]; then
            IFS=',' read -ra PAIRS <<< "$VERDICTS"
            for pair in "${PAIRS[@]}"; do
                idx="${pair%%=*}"
                val="${pair#*=}"
                VERDICT_MAP["$idx"]="$val"
            done
        fi

        VERSION="$(jq -r '.target_version' <<< "$CASE_JSON")"
        echo "=== Grading eval case ${ID} (target ${VERSION}) ==="
        echo

        # Weak mechanical signal only: does the response even mention the
        # target version string? This is NOT a substitute for judging the
        # assertions below -- a response can mention "10.4" and still be
        # wrong. It's printed purely as a sanity hint.
        if grep -qF "$VERSION" "$RESPONSE_FILE"; then
            echo "[hint] response text mentions target version '${VERSION}': yes"
        else
            echo "[hint] response text mentions target version '${VERSION}': no"
        fi
        echo

        mapfile -t ASSERTIONS < <(jq -r '.assertions[]' <<< "$CASE_JSON")
        ALL_JUDGED=1
        ALL_PASS=1
        i=0
        for assertion in "${ASSERTIONS[@]}"; do
            i=$((i + 1))
            verdict="${VERDICT_MAP[$i]:-}"
            if [[ -z "$verdict" ]]; then
                echo "  [${i}] NEEDS-HUMAN-JUDGMENT: ${assertion}"
                ALL_JUDGED=0
            elif [[ "$verdict" == "pass" ]]; then
                echo "  [${i}] PASS: ${assertion}"
            else
                echo "  [${i}] FAIL: ${assertion}"
                ALL_PASS=0
            fi
        done
        echo

        if [[ "$ALL_JUDGED" -ne 1 ]]; then
            echo "RESULT: INCOMPLETE (one or more assertions not judged — pass --verdicts covering every assertion index)"
            exit 2
        elif [[ "$ALL_PASS" -eq 1 ]]; then
            echo "RESULT: PASS"
            exit 0
        else
            echo "RESULT: FAIL"
            exit 1
        fi
        ;;

    *)
        usage
        exit 2
        ;;
esac
