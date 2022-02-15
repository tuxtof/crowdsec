#!/usr/bin/env bats
# vim: ft=sh:list:ts=8:sts=4:sw=4:et:ai:si:

set -u

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
#shellcheck source=tests/bats/lib/assert-crowdsec-not-running.sh
. "${LIB}/assert-crowdsec-not-running.sh"

#declare stderr
CSCLI="${BIN_DIR}/cscli"
#CROWDSEC="${BIN_DIR}/crowdsec"

fake_log() {
    for _ in $(seq 1 6) ; do
        echo "$(LC_ALL=C date '+%b %d %H:%M:%S ')"'sd-126005 sshd[12422]: Invalid user netflix from 1.1.1.172 port 35424'
    done;
}

setup_file() {
    echo "# --- $(basename "${BATS_TEST_FILENAME}" .bats)" >&3
    # we reset config and data, but don't start the daemon
    # ${TEST_DIR}/instance-data load
    # fake_log | ${CROWDSEC} -dsn file:///dev/fd/0 -type syslog -no-api
}

setup() {
    skip
    load "${LIB}/bats-support/load.bash"
    load "${LIB}/bats-assert/load.bash"
}

#----------

@test "we have one decision" {
    run "${CSCLI}" decisions list -o json
    assert_success
    [[ $(echo "$output" | jq '. | length') -eq 1 ]]
}

@test "1.1.1.172 has been banned" {
    run "${CSCLI}" decisions list -o json
    assert_success
    [[ $(echo "$output" | jq -r '.[].decisions[0].value') = "1.1.1.172" ]]
}

@test "1.1.1.172 has been banned (range/contained: -r 1.1.1.0/24 --contained)" {
    run "${CSCLI}" decisions list -r 1.1.1.0/24 --contained -o json
    assert_success
    [[ $(echo "$output" | jq -r '.[].decisions[0].value') = "1.1.1.172" ]]
}

@test "1.1.1.172 has not been banned (range/NOT-contained: -r 1.1.2.0/24)" {
    run "${CSCLI}" decisions list -r 1.1.2.0/24 -o json
    assert_success
    [[ $(echo "$output" | jq -r '.') = "null" ]]
}

@test "1.1.1.172 has been banned (exact: -i 1.1.1.172)" {
    run "${CSCLI}" decisions list -i 1.1.1.172 -o json
    assert_success
    [[ $(echo "$output" | jq -r '.[].decisions[0].value') = "1.1.1.172" ]]
}

@test "1.1.1.173 has not been banned (exact: -i 1.1.1.173)" {
    run "${CSCLI}" decisions list -i 1.1.1.173 -o json
    assert_success
    [[ $(echo "$output" | jq -r '.') = "null" ]]
}


# XXX TODO
## generate a live ssh bf
#
#${CSCLI} decisions delete --all
#
#sudo cp /etc/crowdsec/acquis.yaml ./acquis.yaml.backup
#echo "" | sudo tee -a /etc/crowdsec/acquis.yaml > /dev/null
#echo "filename: /tmp/test.log" | sudo tee -a /etc/crowdsec/acquis.yaml > /dev/null
#echo "labels:" | sudo tee -a /etc/crowdsec/acquis.yaml > /dev/null
#echo "  type: syslog" | sudo tee -a /etc/crowdsec/acquis.yaml > /dev/null
#touch /tmp/test.log
#
#${SYSTEMCTL} restart crowdsec
#wait_for_service "crowdsec should run (cold logs)"
#${SYSTEMCTL} status crowdsec
#
#sleep 2s
#
#cat ssh-bf.log >> /tmp/test.log
#
#sleep 5s
#${CSCLI} decisions list -o=json | ${JQ} '.[].decisions[0].value == "1.1.1.172"' || fail "(live) expected ban on 1.1.1.172"
#
#sudo cp ./acquis.yaml.backup /etc/crowdsec/acquis.yaml
#
