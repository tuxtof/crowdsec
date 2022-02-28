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
    :
}

#----------

@test "test without -no-cs flag" {
    run --separate-stderr timeout 1s "${CROWDSEC}"
    # from `man timeout`: If  the  command  times  out,  and --preserve-status is not set, then exit with status 124.
    assert_failure 124
}

@test "crowdsec should not run without agent (-no-cs flag)" {
    skip
    run --separate-stderr timeout 1s "${CROWDSEC}" -no-cs
    echo "$stderr" >&3
    assert_failure 1
}

@test "crowdsec should not run without LAPI (no api.server in configuration file)" {
    skip
    yq 'del(.api.server)' -i "${CONFIG_DIR}/config.yaml"
    run --separate-stderr timeout 1s "${CROWDSEC}"
    [[ "$stderr" == *"crowdsec local API is disabled"* ]]
    assert_failure 1
}

@test "capi status shouldn't be ok without api.server" {
    skip
    yq 'del(.api.server)' -i "${CONFIG_DIR}/config.yaml"
    run --separate-stderr "${CSCLI}" capi status
    [[ "$stderr" == *"Local API is disabled, please run this command on the local API machine"* ]]
    assert_failure 1
}

@test "lapi status shouldn't be ok without api.server" {
    skip
    yq 'del(.api.server)' -i "${CONFIG_DIR}/config.yaml"
    run --separate-stderr "${CSCLI}" lapi status
    # XXX which message do we expect?
    # echo $stderr >&3
    # [[ "$stderr" == *"Local API is disabled, please run this command on the local API machine"* ]]
    assert_failure 1
}



# testNoAgent_LAPI_CAPI() {
#     :
#     ## test with -no-cs flag
#     #sed '/^ExecStart/ s/$/ -no-cs/' /etc/systemd/system/crowdsec.service > /tmp/crowdsec.service
#     #sudo mv /tmp/crowdsec.service /etc/systemd/system/crowdsec.service
#     #
#     #
#     #${SYSTEMCTL} daemon-reload
#     #${SYSTEMCTL} start crowdsec
#     #wait_for_service "crowdsec LAPI should run without agent (in flag)"
#     #${SYSTEMCTL} stop crowdsec
#     #
#     #sed '/^ExecStart/s/-no-cs//g' ${SYSTEMD_SERVICE_FILE} > /tmp/crowdsec.service
#     #sudo mv /tmp/crowdsec.service /etc/systemd/system/crowdsec.service
#     #
#     #${SYSTEMCTL} daemon-reload
#     #
#     ## test with no crowdsec agent in configuration file
#     #sudo cp ./config/config_no_agent.yaml /etc/crowdsec/config.yaml
#     #${SYSTEMCTL} start crowdsec
#     #wait_for_service "crowdsec LAPI should run without agent (in configuration file)"
#     #
#     #
#     ### capi
#     #${CSCLI} -c ./config/config_no_agent.yaml capi status || fail "capi status should be ok"
#     ### config
#     #${CSCLI_BIN} -c ./config/config_no_agent.yaml config show || fail "failed to show config"
#     #${CSCLI} -c ./config/config_no_agent.yaml config backup ./test || fail "failed to backup config"
#     #sudo rm -rf ./test
#     ### lapi
#     #${CSCLI} -c ./config/config_no_agent.yaml lapi status || fail "lapi status failed"
#     ### metrics
#     #${CSCLI_BIN} -c ./config/config_no_agent.yaml metrics || fail "failed to get metrics"
#     #
#     #${SYSTEMCTL} stop crowdsec
#     #sudo cp ./config/config.yaml /etc/crowdsec/config.yaml
# }
#
