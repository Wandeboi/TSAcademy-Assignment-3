#!/usr/bin/env bash
#
# tests/test.sh
#
# Test suite for app/app.sh. Runs the CLI directly (no Docker required)
# so it's fast enough to run in the CI "test" job before the Docker
# build/smoke-test stage.
#
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${SCRIPT_DIR}/../app/app.sh"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "======================================"
echo " app.sh Test Suite"
echo "======================================"
echo

if [[ ! -x "${APP}" ]]; then
    echo "ERROR: ${APP} not found or not executable" >&2
    exit 2
fi

# 1. help
output="$("${APP}" help 2>&1)"
rc=$?
if [[ ${rc} -eq 0 ]] && echo "${output}" | grep -qi "usage"; then
    pass "help succeeds and shows usage"
else
    fail "help did not behave as expected (exit ${rc})"
fi

# 2. system-info
output="$("${APP}" system-info 2>&1)"
rc=$?
if [[ ${rc} -eq 0 ]] && echo "${output}" | grep -qi "hostname"; then
    pass "system-info succeeds and shows system info"
else
    fail "system-info did not behave as expected (exit ${rc})"
fi

# 3. invalid command
"${APP}" totally-bogus-command >/dev/null 2>&1
rc=$?
if [[ ${rc} -eq 2 ]]; then
    pass "invalid command returns exit code 2"
else
    fail "invalid command should return exit code 2 (got ${rc})"
fi

# 4. missing command entirely
"${APP}" >/dev/null 2>&1
rc=$?
if [[ ${rc} -eq 2 ]]; then
    pass "missing command returns exit code 2"
else
    fail "missing command should return exit code 2 (got ${rc})"
fi

# 5. check-host with missing host
"${APP}" check-host >/dev/null 2>&1
rc=$?
if [[ ${rc} -eq 2 ]]; then
    pass "check-host with missing host returns exit code 2"
else
    fail "check-host with missing host should return exit code 2 (got ${rc})"
fi

# 6. check-host with a valid host
output="$("${APP}" check-host localhost 2>&1)"
rc=$?
if [[ ${rc} -eq 0 || ${rc} -eq 1 ]] && echo "${output}" | grep -qi "Resolved Address"; then
    pass "check-host with a valid host resolves and runs"
else
    fail "check-host localhost did not behave as expected (exit ${rc})"
fi

# 7. check-port with missing port
"${APP}" check-port localhost >/dev/null 2>&1
rc=$?
if [[ ${rc} -eq 2 ]]; then
    pass "check-port with missing port returns exit code 2"
else
    fail "check-port with missing port should return exit code 2 (got ${rc})"
fi

# 8. check-port with a non-numeric port
"${APP}" check-port localhost abc >/dev/null 2>&1
rc=$?
if [[ ${rc} -eq 2 ]]; then
    pass "check-port with non-numeric port returns exit code 2"
else
    fail "check-port with non-numeric port should return exit code 2 (got ${rc})"
fi

# 9. check-port with an out-of-range port (0)
"${APP}" check-port localhost 0 >/dev/null 2>&1
rc=$?
if [[ ${rc} -eq 2 ]]; then
    pass "check-port with port 0 returns exit code 2"
else
    fail "check-port with port 0 should return exit code 2 (got ${rc})"
fi

# 10. check-port with an out-of-range port (65536)
"${APP}" check-port localhost 65536 >/dev/null 2>&1
rc=$?
if [[ ${rc} -eq 2 ]]; then
    pass "check-port with port 65536 returns exit code 2"
else
    fail "check-port with port 65536 should return exit code 2 (got ${rc})"
fi

echo
echo "======================================"
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
echo "======================================"

[[ ${FAIL} -eq 0 ]]
