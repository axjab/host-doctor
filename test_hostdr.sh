#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/hostdr"

assert_status() {
    local expected=$1 actual
    shift
    actual=$("$@" | jq -r '.status')
    if [[ $actual != "$expected" ]]; then
        printf 'FAIL: %s: expected %s, got %s\n' "$*" "$expected" "$actual" >&2
        exit 1
    fi
}

assert_status ok   check_mullvad '{"mullvad_exit_ip":true}'
assert_status fail check_mullvad '{"mullvad_exit_ip":false}'
assert_status fail check_mullvad ''
assert_status info check_location City city '{"city":"Ottawa"}'
assert_status fail check_ssh_password 'passwordauthentication yes'
assert_status ok   check_ssh_password 'passwordauthentication no'
assert_status warn check_ssh_root 'permitrootlogin prohibit-password'
assert_status fail check_ssh_root 'permitrootlogin yes'

df() {
    printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\n'
    printf 'test 100 %s 10 %s%% /\n' "$TEST_USED" "$TEST_USED"
}
TEST_USED=50; assert_status ok   check_disk /
TEST_USED=80; assert_status warn check_disk /
TEST_USED=95; assert_status fail check_disk /

findmnt() { printf '%s\n' "$TEST_OPTIONS"; }
TEST_OPTIONS='rw,relatime'; assert_status ok   check_mount /
TEST_OPTIONS='ro,relatime'; assert_status fail check_mount /

ufw() { printf '%s\n' 'Status: inactive'; }
nft() { printf '%s\n' "$TEST_RULESET"; }
TEST_RULESET='{"nftables":[{"chain":{"family":"inet","hook":"input","policy":"drop"}}]}'
assert_status ok check_firewall
TEST_RULESET='{"nftables":[{"chain":{"family":"ip","hook":"input","policy":"drop"}}]}'
assert_status warn check_firewall

systemctl() {
    case "$1" in
        is-active) printf 'active\n' ;;
        is-enabled) printf 'enabled\n' ;;
    esac
}
assert_status ok check_service ssh

printf 'All 16 tests passed.\n' 
