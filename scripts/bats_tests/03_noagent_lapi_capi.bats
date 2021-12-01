#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
. "$LIB/wrap-init.sh"

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME})" >&3
  "$SYSTEMCTL" start crowdsec
}

#-------


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
