#!/usr/bin/env bats
# vim: ft=sh:list:ts=8:sts=4:sw=4:et:ai:si:

set -u

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
#shellcheck source=tests/bats/lib/assert-crowdsec-not-running.sh
. "${LIB}/assert-crowdsec-not-running.sh"

# declare stderr
CSCLI="${BIN_DIR}/cscli"
CROWDSEC="${BIN_DIR}/crowdsec"

fake_log() {
    for _ in $(seq 1 10) ; do
        echo "$(LC_ALL=C date '+%b %d %H:%M:%S ')"'sd-126005 sshd[12422]: Invalid user netflix from 1.1.1.174 port 35424'
    done;
}

setup_file() {
    echo "# --- $(basename "${BATS_TEST_FILENAME}" .bats)" >&3
    # we reset config and data, but don't start the daemon
    # ${TEST_DIR}/instance-data load
    # $(CSCLI) collections install crowdsecurity/sshd
    # $(CSCLI) scenarios install crowdsecurity/ssh-bf
    # ${CSCLI} decisions delete --all
    # ${CSCLI} simulation disable --global
    # fake_log | ${CSCLI} -dsn file:///dev/fd/0 -type syslog -no-api
}

teardown_file() {
    :
    # ${CSCLI} decisions delete --all
    # ${CSCLI} simulation disable --global
}

setup() {
    load "${LIB}/bats-support/load.bash"
    load "${LIB}/bats-assert/load.bash"
}

#----------

@test "we have one decision" {
    skip
    run "${CSCLI}" decisions list -o json
    assert_success
    [[ $(echo "$output" | jq '. | length') -eq 1 ]]
}

@test "1.1.1.174 has been banned (exact)" {
    skip
    run "${CSCLI}" decisions list -o json
    assert_success
    [[ $(echo "$output" | jq -r '.[].decisions[0].value') = "1.1.1.174" ]]
}

@test "decision has simulated == false (exact)" {
    skip
    run "${CSCLI}" decisions list -o json
    assert_success
    [[ $(echo "$output" | jq -r '.[].decisions[0].simulated') = "false" ]]
}

@test "simulated scenario, listing non-simulated: expect no decision" {
    skip
    run "${CSCLI}" decisions delete --all
    run "${CSCLI}" simulation enable crowdsecurity/ssh-bf
    fake_log | ${CROWDSEC} -dsn file:///dev/fd/0 -type syslog -no-api
    ${CSCLI} decisions list --no-simu -o json
    assert_success
    [[ $(echo "$output" | jq -r '.') = "null" ]]
}

@test "global simulation, listing non-simulated: expect no decision" {
    skip
    ${CSCLI} decisions delete --all
    ${CSCLI} simulation disable crowdsecurity/ssh-bf
    ${CSCLI} simulation enable --global
    fake_log | ${CROWDSEC} -dsn file:///dev/fd/0 -type syslog -no-api
    ${CSCLI} decisions list --no-simu -o json
    assert_success
    [[ $(echo "$output" | jq -r '.') = "null" ]]
}
