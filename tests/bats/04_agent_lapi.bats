#!/usr/bin/env bats
# vim: ft=bats:list:ts=8:sts=4:sw=4:et:ai:si:

set -u

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
#shellcheck source=tests/bats/lib/assert-crowdsec-not-running.sh
. "${LIB}/assert-crowdsec-not-running.sh"

#declare stderr
#CSCLI="${BIN_DIR}/cscli"


setup_file() {
    echo "# --- $(basename "${BATS_TEST_FILENAME}" .bats)" >&3
}

setup() {
    load "${LIB}/bats-support/load.bash"
    load "${LIB}/bats-assert/load.bash"
    "${TEST_DIR}/instance-data" load
    "${TEST_DIR}/instance-crowdsec" start
}

teardown() {
    "${TEST_DIR}/instance-crowdsec" stop
}

#----------


# testAgent_LAPI() {
#     :
#     ## test with no online client in configuration file
#     #sudo cp ./config/config_no_capi.yaml /etc/crowdsec/config.yaml
#     #${SYSTEMCTL} start crowdsec
#     #wait_for_service "crowdsec LAPI should run without CAPI (in configuration file)"
#     #
#     ### capi
#     #${CSCLI} -c ./config/config_no_capi.yaml capi status && fail "capi status should not be ok" ## if capi status success, it means that the test fail
#     ### config
#     #${CSCLI_BIN} -c ./config/config_no_capi.yaml config show || fail "failed to show config"
#     #${CSCLI} -c ./config/config_no_capi.yaml config backup ./test || fail "failed to backup config"
#     #sudo rm -rf ./test
#     ### lapi
#     #${CSCLI} -c ./config/config_no_capi.yaml lapi status || fail "lapi status failed"
#     ### metrics
#     #${CSCLI_BIN} -c ./config/config_no_capi.yaml metrics || fail "failed to get metrics"
#     #
#     #sudo mv /tmp/crowdsec.service-orig /etc/systemd/system/crowdsec.service
#     #
#     #sudo cp ./config.yaml.backup /etc/crowdsec/config.yaml
#     #
#     #${SYSTEMCTL} daemon-reload
#     #${SYSTEMCTL} restart crowdsec
#     #wait_for_service "crowdsec should be restarted)"
# }
#
