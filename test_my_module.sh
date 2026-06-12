#!/bin/zsh
# Test my_module using source (so exports persist in the shell)

PASS=0; FAIL=0
assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        echo "FAIL: $desc"
        echo "  expected: '$expected'"
        echo "  actual:   '$actual'"
    fi
}
assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        echo "FAIL: $desc — '$needle' not in output"
    fi
}
assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        echo "FAIL: $desc — '$needle' unexpectedly found"
    fi
}
assert_rc() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        echo "FAIL: $desc — rc expected=$expected actual=$actual"
    fi
}

# Setup: clean test environment
TEST_DB="/tmp/test_module_db_$$"
TEST_MOD="/tmp/test_mod_$$"
rm -rf "${TEST_DB}" "${TEST_MOD}"
mkdir -p "${TEST_DB}" "${TEST_MOD}/bin" "${TEST_MOD}/sbin" "${TEST_MOD}/lib" "${TEST_MOD}/include" "${TEST_MOD}/pkgconfig"

# Save original PATH
ORIG_PATH="${PATH}"

# Source the script with custom DB dir
MODULE_DB_DIR="${TEST_DB}" source /home/lilew/bin/my_module

echo "=== Test 1: help ==="
out=$(module help 2>&1); rc=$?
assert_contains "help shows usage" "$out" "Usage: module"
assert_rc "help returns 1" "1" "$rc"

out=$(module --help 2>&1); rc=$?
assert_contains "--help shows usage" "$out" "Usage: module"

out=$(module -h 2>&1); rc=$?
assert_contains "-h shows usage" "$out" "Usage: module"

echo "=== Test 2: no args ==="
out=$(module 2>&1); rc=$?
assert_contains "no args shows usage" "$out" "Usage: module"
assert_rc "no args returns 1" "1" "$rc"

echo "=== Test 3: install ==="
module install testmod "${TEST_MOD}"; rc=$?
assert_rc "install succeeds" "0" "$rc"
assert_eq "db file exists" "yes" "$([[ -f ${TEST_DB}/testmod ]] && echo yes || echo no)"

echo "=== Test 4: install duplicate ==="
out=$(module install testmod "${TEST_MOD}" 2>&1); rc=$?
assert_rc "duplicate install fails" "3" "$rc"
assert_contains "duplicate install error" "$out" "already exists"

echo "=== Test 5: install invalid name ==="
out=$(module install "../evil" 2>&1); rc=$?
assert_rc "invalid name rejected" "1" "$rc"
assert_contains "invalid name error" "$out" "Invalid module name"

echo "=== Test 6: load ==="
module load testmod; rc=$?
assert_rc "load succeeds" "0" "$rc"
assert_contains "PATH has testmod/bin" "$PATH" "${TEST_MOD}/bin"
assert_contains "PATH has testmod/sbin" "$PATH" "${TEST_MOD}/sbin"
assert_contains "LD_LIBRARY_PATH has testmod/lib" "${LD_LIBRARY_PATH:-}" "${TEST_MOD}/lib"
assert_contains "C_INCLUDE_PATH has testmod/include" "${C_INCLUDE_PATH:-}" "${TEST_MOD}/include"
assert_contains "PKG_CONFIG_PATH has testmod/pkgconfig" "${PKG_CONFIG_PATH:-}" "${TEST_MOD}/pkgconfig"

echo "=== Test 7: load non-existent ==="
out=$(module load nonexistent 2>&1); rc=$?
assert_rc "load nonexistent fails" "1" "$rc"
assert_contains "load nonexistent error" "$out" "not found"

echo "=== Test 8: load duplicate (no double path) ==="
PATH_BEFORE="$PATH"
module load testmod
assert_eq "no duplicate PATH entry" "$PATH_BEFORE" "$PATH"

echo "=== Test 9: list ==="
out=$(module list 2>&1)
assert_contains "list shows testmod" "$out" "testmod"

echo "=== Test 10: avail ==="
out=$(module avail 2>&1)
assert_contains "avail shows testmod" "$out" "testmod"

echo "=== Test 11: swap ==="
# Install a second module
TEST_MOD2="/tmp/test_mod2_$$"
mkdir -p "${TEST_MOD2}/bin" "${TEST_MOD2}/lib"
module install testmod2 "${TEST_MOD2}"
module load testmod2
assert_contains "PATH has testmod2/bin" "$PATH" "${TEST_MOD2}/bin"

module swap testmod testmod2; rc=$?
assert_rc "swap succeeds" "0" "$rc"
assert_not_contains "PATH no longer has testmod/bin" "$PATH" "${TEST_MOD}/bin"
assert_contains "PATH still has testmod2/bin" "$PATH" "${TEST_MOD2}/bin"

echo "=== Test 12: unload ==="
module unload testmod2; rc=$?
assert_rc "unload succeeds" "0" "$rc"
assert_not_contains "PATH no longer has testmod2/bin" "$PATH" "${TEST_MOD2}/bin"
assert_not_contains "LD_LIBRARY_PATH no longer has testmod2/lib" "${LD_LIBRARY_PATH:-}" "${TEST_MOD2}/lib"

echo "=== Test 13: unload non-existent ==="
out=$(module unload nosuchmodule 2>&1); rc=$?
assert_rc "unload nonexistent fails" "1" "$rc"

echo "=== Test 14: remove ==="
module remove testmod; rc=$?
assert_rc "remove succeeds" "0" "$rc"
assert_eq "db file gone" "no" "$([[ -f ${TEST_DB}/testmod ]] && echo yes || echo no)"

echo "=== Test 15: remove non-existent ==="
out=$(module remove nosuchmodule 2>&1); rc=$?
assert_rc "remove nonexistent fails" "1" "$rc"
assert_contains "remove nonexistent error" "$out" "not found"

echo "=== Test 16: unknown command ==="
out=$(module bogus 2>&1); rc=$?
assert_rc "unknown command fails" "1" "$rc"
assert_contains "unknown command error" "$out" "Unknown command"

# Cleanup
rm -rf "${TEST_DB}" "${TEST_MOD}" "${TEST_MOD2}"

echo ""
echo "==============================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "==============================="
[[ ${FAIL} -eq 0 ]]
