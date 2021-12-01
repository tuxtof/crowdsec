#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
. "$LIB/wrap-init.sh"

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME})" >&3
  "$SYSTEMCTL" start crowdsec
}

#-------


# 
# 
# testAgent_NOAPI() {
#     :
# #    ## test with -no-api flag
# #    cp ${SYSTEMD_SERVICE_FILE} /tmp/crowdsec.service-orig
# #    sed '/^ExecStart/ s/$/ -no-api/' ${SYSTEMD_SERVICE_FILE} > /tmp/crowdsec.service
# #    sudo mv /tmp/crowdsec.service /etc/systemd/system/crowdsec.service
# #
# #    ${SYSTEMCTL} daemon-reload
# #    ${SYSTEMCTL} start crowdsec
# #    sleep 1
# #    pgrep -x crowdsec && fail "crowdsec shouldn't run without LAPI (in flag)"
# #    ${SYSTEMCTL} stop crowdsec
# #
# #    sudo cp /tmp/crowdsec.service-orig /etc/systemd/system/crowdsec.service
# #
# #    ${SYSTEMCTL} daemon-reload
# #
# #    # test with no api server in configuration file
# #    sudo cp ./config/config_no_lapi.yaml /etc/crowdsec/config.yaml
# #    ${SYSTEMCTL} start crowdsec
# #    sleep 1
# #    pgrep -x crowdsec && fail "crowdsec agent should not run without lapi (in configuration file)"
# 
# #    ##### cscli test ####
# #    ## capi
# #    ${CSCLI} -c ./config/config_no_lapi.yaml capi status && fail "capi status shouldn't be ok"
# #    ## config
# #    ${CSCLI_BIN} -c ./config/config_no_lapi.yaml config show || fail "failed to show config"
# #    ${CSCLI} -c ./config/config_no_lapi.yaml config backup ./test || fail "failed to backup config"
# #    sudo rm -rf ./test
# #    ## lapi
# #    ${CSCLI} -c ./config/config_no_lapi.yaml lapi status && fail "lapi status should not be ok" ## if lapi status success, it means that the test fail
# #    ## metrics
# #    ${CSCLI_BIN} -c ./config/config_no_lapi.yaml metrics
# 
# #    ${SYSTEMCTL} stop crowdsec
# #    sudo cp ./config/config.yaml /etc/crowdsec/config.yaml
# }
# 
# 
