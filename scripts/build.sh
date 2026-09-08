#!/usr/bin/env bash
#
# build.sh
#
# Builds the devops-tool Docker image and performs a small set of
# smoke tests against it: help, system-info, and an invalid command.
#
set -u

IMAGE="${IMAGE_NAME:-devops-tool}"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "======================================"
echo " Build & Smoke Test"
echo "======================================"
echo

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is required to build and smoke test the image." >&2
    exit 2
fi

echo "Building image '${IMAGE}'..."
if docker build -t "${IMAGE}" . >/tmp/devops-tool-build.log 2>&1; then
    pass "Docker image builds successfully"
else
    fail "Docker image failed to build"
    cat /tmp/devops-tool-build.log
    echo
    echo "======================================"
    echo "Passed: ${PASS}"
    echo "Failed: ${FAIL}"
    echo "======================================"
    exit 1
fi

# Smoke test: help
output="$(docker run --rm "${IMAGE}" help 2>&1)"
rc=$?
if [[ ${rc} -eq 0 ]] && echo "${output}" | grep -qi "usage"; then
    pass "Smoke test: help command works"
else
    fail "Smoke test: help command failed (exit ${rc})"
    echo "${output}"
fi

# Smoke test: system-info
output="$(docker run --rm "${IMAGE}" system-info 2>&1)"
rc=$?
if [[ ${rc} -eq 0 ]] && echo "${output}" | grep -qi "hostname"; then
    pass "Smoke test: system-info command works"
else
    fail "Smoke test: system-info command failed (exit ${rc})"
    echo "${output}"
fi

# Smoke test: invalid command must fail
output="$(docker run --rm "${IMAGE}" not-a-real-command 2>&1)"
rc=$?
if [[ ${rc} -ne 0 ]]; then
    pass "Smoke test: invalid command returns non-zero"
else
    fail "Smoke test: invalid command should return non-zero"
    echo "${output}"
fi

echo
echo "======================================"
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
echo "======================================"

[[ ${FAIL} -eq 0 ]]
