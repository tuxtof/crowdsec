#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
. "$LIB/wrap-init.sh"

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME} .bats)" >&3
  "$SYSTEMCTL" start crowdsec || "$SYSTEMCTL" restart crowdsec
}

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
}

#----------


# 
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
