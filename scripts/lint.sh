#!/usr/bin/env bash
#
# lint.sh
#
# Validates the project: checks that required files exist and runs
# `bash -n` (syntax check) against every Bash script. Runs ShellCheck
# as well when it's available, as an extra (non-blocking) check.
#
set -u

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "======================================"
echo " Lint"
echo "======================================"
echo

REQUIRED_FILES=(
    "README.md"
    "app/app.sh"
    "scripts/lint.sh"
    "scripts/build.sh"
    "tests/test.sh"
    "Dockerfile"
    "compose.yaml"
    ".dockerignore"
    ".github/workflows/ci.yml"
)

echo "--- Required files ---"
for f in "${REQUIRED_FILES[@]}"; do
    if [[ -f "${f}" ]]; then
        pass "Required file exists: ${f}"
    else
        fail "Missing required file: ${f}"
    fi
done

echo
echo "--- Bash syntax ---"
SCRIPT_FILES=(app/*.sh scripts/*.sh tests/*.sh)
for f in "${SCRIPT_FILES[@]}"; do
    [[ -f "${f}" ]] || continue
    if bash -n "${f}" >/dev/null 2>&1; then
        pass "Bash syntax: ${f}"
    else
        fail "Bash syntax error: ${f}"
        bash -n "${f}"
    fi
done

echo
echo "--- ShellCheck (optional) ---"
if command -v shellcheck >/dev/null 2>&1; then
    for f in "${SCRIPT_FILES[@]}"; do
        [[ -f "${f}" ]] || continue
        if shellcheck "${f}"; then
            pass "ShellCheck clean: ${f}"
        else
            echo "WARN: ShellCheck reported issues in ${f} (non-blocking)"
        fi
    done
else
    echo "WARN: shellcheck not installed; skipping (non-blocking)"
fi

echo
echo "======================================"
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
echo "======================================"

[[ ${FAIL} -eq 0 ]]
