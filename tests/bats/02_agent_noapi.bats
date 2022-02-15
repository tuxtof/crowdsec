#!/usr/bin/env bats
# vim: ft=sh:list:ts=8:sts=4:sw=4:et:ai:si:

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
    # reset config and data but don't run the daemon
    "${TEST_DIR}/instance-data" load
}

teardown() {
:
}

#----------

@test "test without -no-api flag" {
    run --separate-stderr timeout 1s "${CROWDSEC}"
    # from `man timeout`: If  the  command  times  out,  and --preserve-status is not set, then exit with status 124.
    assert_failure 124
}

@test "crowdsec should not run without LAPI (-no-api flag)" {
    run --separate-stderr timeout 1s "${CROWDSEC}" -no-api
    assert_failure 1
}

@test "crowdsec should not run without LAPI (no api.server in configuration file)" {
    yq 'del(.api.server)' -i "${CONFIG_DIR}/config.yaml"
    run --separate-stderr timeout 1s "${CROWDSEC}"
    [[ "$stderr" == *"crowdsec local API is disabled"* ]]
    assert_failure 1
}

@test "capi status shouldn't be ok without api.server" {
    yq 'del(.api.server)' -i "${CONFIG_DIR}/config.yaml"
    run --separate-stderr "${CSCLI}" capi status
    [[ "$stderr" == *"Local API is disabled, please run this command on the local API machine"* ]]
    assert_failure 1
}

@test "lapi status shouldn't be ok without api.server" {
    yq 'del(.api.server)' -i "${CONFIG_DIR}/config.yaml"
    run --separate-stderr "${CSCLI}" lapi status
    # XXX which message do we expect?
    # echo $stderr >&3
    # [[ "$stderr" == *"Local API is disabled, please run this command on the local API machine"* ]]
    assert_failure 1
}


# XXX TODO
# #    ## metrics
# #    ${CSCLI_BIN} -c ./config/config_no_lapi.yaml metrics
#
# #    ${SYSTEMCTL} stop crowdsec
# #    sudo cp ./config/config.yaml /etc/crowdsec/config.yaml
