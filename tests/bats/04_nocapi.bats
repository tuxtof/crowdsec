#!/usr/bin/env bats
# vim: ft=bats:list:ts=8:sts=4:sw=4:et:ai:si:

set -u

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
#shellcheck source=tests/bats/lib/assert-crowdsec-not-running.sh
. "${LIB}/assert-crowdsec-not-running.sh"

declare stderr
CSCLI="${BIN_DIR}/cscli"
CROWDSEC="${BIN_DIR}/crowdsec"


setup_file() {
    echo "# --- $(basename "${BATS_TEST_FILENAME}" .bats)" >&3
}

setup() {
    load "${LIB}/bats-support/load.bash"
    load "${LIB}/bats-assert/load.bash"
    "${TEST_DIR}/instance-data" load
}

teardown() {
    "${TEST_DIR}/instance-crowdsec" stop
}

#----------

config_disable_capi() {
    yq 'del(.api.server.online_client)' -i "${CONFIG_DIR}/config.yaml"
}

@test "without capi: crowdsec LAPI should still work" {
    config_disable_capi
    run --separate-stderr timeout 1s "${CROWDSEC}"
    # from `man timeout`: If  the  command  times  out,  and --preserve-status is not set, then exit with status 124.
    [[ "$stderr" == *"push and pull to Central API disabled"* ]]
    assert_failure 124
}

@test "without capi: cscli capi status -> fail" {
    config_disable_capi
    "${TEST_DIR}/instance-crowdsec" start
    run --separate-stderr "${CSCLI}" capi status
    [[ "$stderr" == *"no configuration for Central API in "* ]]
    assert_failure
}

@test "no capi: cscli config show" {
    config_disable_capi
    run --separate-stderr "${CSCLI}" config show -o human
    assert_success
    assert_output --partial "Global:"
    assert_output --partial "cscli:"
    assert_output --partial "Crowdsec:"
    assert_output --partial "Local API Server:"
}

@test "no agent: cscli config backup" {
    config_disable_capi
    tempdir=$(mktemp -u)
    run "${CSCLI}" config backup "${tempdir}"
    assert_success
    assert_output --partial "Starting configuration backup"
    run --separate-stderr "${CSCLI}" config backup "${tempdir}"
    assert_failure
    [[ "$stderr" == *"Failed to backup configurations"* ]]
    [[ "$stderr" == *"file exists"* ]]
    rm -rf -- "${tempdir:?}"
}

@test "without capi: cscli lapi status -> success" {
    config_disable_capi
    "${TEST_DIR}/instance-crowdsec" start
    run --separate-stderr "${CSCLI}" lapi status
    assert_success
    [[ "$stderr" == *"You can successfully interact with Local API (LAPI)"* ]]
}

@test "cscli metrics" {
    config_disable_capi
    "${TEST_DIR}/instance-crowdsec" start
    run --separate-stderr "${CSCLI}" metrics
    assert_success
}
