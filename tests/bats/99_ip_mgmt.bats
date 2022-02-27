#!/usr/bin/env bats
# vim: ft=sh:list:ts=8:sts=4:sw=4:et:ai:si:


# XXX TODO split in multile files w/ setup_file, teardown_file

set -u

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
#shellcheck source=tests/bats/lib/assert-crowdsec-not-running.sh
. "${LIB}/assert-crowdsec-not-running.sh"

declare stderr
CSCLI="${BIN_DIR}/cscli"


setup_file() {
    echo "# --- $(basename "${BATS_TEST_FILENAME}" .bats)" >&3
}

teardown_file() {
    :
}

setup() {
    load "${LIB}/bats-support/load.bash"
    load "${LIB}/bats-assert/load.bash"
    "${TEST_DIR}/instance-data" load
    "${TEST_DIR}/instance-crowdsec" start
    API_KEY=$("${CSCLI}" bouncers add testbouncer -o raw)
}

teardown() {
    "${TEST_DIR}/instance-crowdsec" stop
}

#----------

CROWDSEC_API_URL="http://localhost:8080"

docurl() {
    URI="$1"
    curl -s -H "X-Api-Key: ${API_KEY}" "${CROWDSEC_API_URL}${URI}"
}

@test 'test ipv4' {
    #
    # TEST SINGLE IPV4
    #

    # cscli: first decisions list (must be empty)
    run "${CSCLI}" decisions list -o json
    assert_success
    assert_output 'null'

    # bouncer: first decisions request (must be empty)
    run docurl /v1/decisions
    assert_success
    assert_output 'null'

    # adding decision for 1.2.3.4
    run "${CSCLI}" decisions add -i '1.2.3.4'
    assert_success
    assert_output --partial 'Decision successfully added'

    # cscli: getting all decisions
    run "${CSCLI}" decisions list -o json
    assert_success
    run jq -r '.[0].decisions[0].value' <(echo "$output")
    assert_success
    assert_output '1.2.3.4'

    # check ip match
    # cscli: getting decision for 1.2.3.4
    run "${CSCLI}" decisions list -i '1.2.3.4' -o json
    assert_success
    run jq -r '.[0].decisions[0].value' <(echo "$output")
    assert_success
    assert_output '1.2.3.4'

    # bouncer: getting decision for 1.2.3.4
    run docurl '/v1/decisions?ip=1.2.3.4'
    assert_success
    run jq -r '.[0].value' <(echo "$output")
    assert_success
    assert_output '1.2.3.4'

    # cscli:  getting decision for 1.2.3.5
    run "${CSCLI}" decisions list -i '1.2.3.5' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decision for 1.2.3.5
    run docurl '/v1/decisions?ip=1.2.3.5'
    assert_success
    assert_output 'null'

    # check outer range match

    # cscli: getting decision for 1.2.3.0/24
    run "${CSCLI}" decisions list -r '1.2.3.0/24' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decision for 1.2.3.0/24
    run docurl '/v1/decisions?range=1.2.3.0/24'
    assert_success
    assert_output 'null'

    # cscli: getting decisions where IP in 1.2.3.0/24
    run "${CSCLI}" decisions list -r '1.2.3.0/24' --contained -o json
    assert_success
    run jq -r '.[0].decisions[0].value' <(echo "$output")
    assert_success
    assert_output '1.2.3.4'

    # bouncer: getting decisions where IP in 1.2.3.0/24
    run docurl '/v1/decisions?range=1.2.3.0/24&contains=false'
    assert_success
    run jq -r '.[0].value' <(echo "$output")
    assert_success
    assert_output '1.2.3.4'

    #
    # TEST IPV4 RANGE
    #

    # cscli: adding decision for range 4.4.4.0/24
    run "${CSCLI}" decisions add -r '4.4.4.0/24'
    assert_success
    assert_output --partial 'Decision successfully added'

    # cscli: getting all decisions
    run "${CSCLI}" decisions list -o json
    assert_success
    run jq -r '.[0].decisions[0].value, .[1].decisions[0].value' <(echo "$output")
    assert_success
    assert_output $'4.4.4.0/24\n1.2.3.4'

    # bouncer: getting all decisions
    run docurl '/v1/decisions'
    assert_success
    run jq -r '.[0].value, .[1].value' <(echo "$output")
    assert_success
    assert_output $'1.2.3.4\n4.4.4.0/24'

#    #check ip within/outside of range

    # cscli: getting decisions for ip 4.4.4.
    run "${CSCLI}" decisions list -i '4.4.4.3' -o json
    assert_success
    run jq -r '.[0].decisions[0].value' <(echo "$output")
    assert_success
    assert_output '4.4.4.0/24'

    # bouncer: getting decisions for ip 4.4.4.
    run docurl '/v1/decisions?ip=4.4.4.3'
    assert_success
    run jq -r '.[0].value' <(echo "$output")
    assert_success
    assert_output '4.4.4.0/24'

    # cscli:  getting decisions for ip contained in 4.4.4.
    run "${CSCLI}" decisions list -i '4.4.4.4' -o json --contained
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for ip contained in 4.4.4.
    run docurl '/v1/decisions?ip=4.4.4.4&contains=false'
    assert_success
    assert_output 'null'

    # cscli: getting decisions for ip 5.4.4.
    run "${CSCLI}" decisions list -i '5.4.4.3' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for ip 5.4.4.
    run docurl '/v1/decisions?ip=5.4.4.3'
    assert_success
    assert_output 'null'

    # cscli: getting decisions for range 4.4.0.0/1
    run "${CSCLI}" decisions list -r '4.4.0.0/16' -o json
    assert_success
    assert_output 'null'

    # getting decisions for range 4.4.0.0/1
    run docurl '/v1/decisions?range=4.4.0.0/16'
    assert_success
    assert_output 'null'

    # cscli: getting decisions for ip/range in 4.4.0.0/1
    run "${CSCLI}" decisions list -r '4.4.0.0/16' -o json --contained
    assert_success
    run jq -r '.[0].decisions[0].value' <(echo "$output")
    assert_success
    assert_output '4.4.4.0/24'

    # bouncer: getting decisions for ip/range in 4.4.0.0/1
    run docurl '/v1/decisions?range=4.4.0.0/16&contains=false'
    assert_success
    run jq -r '.[0].value' <(echo "$output")
    assert_success
    assert_output '4.4.4.0/24'

    #check subrange

    # cscli: getting decisions for range 4.4.4.2/2
    run "${CSCLI}" decisions list -r '4.4.4.2/28' -o json
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output '4.4.4.0/24'

    # bouncer: getting decisions for range 4.4.4.2/2
    run docurl '/v1/decisions?range=4.4.4.2/28'
    assert_success
    run jq -r '.[].value' <(echo "$output")
    assert_success
    assert_output '4.4.4.0/24'

    # cscli: getting decisions for range 4.4.3.2/2
    run "${CSCLI}" decisions list -r '4.4.3.2/28' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for range 4.4.3.2/2
    run docurl '/v1/decisions?range=4.4.3.2/28'
    assert_success
    assert_output 'null'
}



@test 'test ipv6' {

    #
    # TEST SINGLE IPV6
    #

    # cscli: adding decision for ip 1111:2222:3333:4444:5555:6666:7777:8888
    run "${CSCLI}" decisions add -i '1111:2222:3333:4444:5555:6666:7777:8888'
    assert_success
    assert_output --partial 'Decision successfully added'

    # cscli: getting all decision
    run "${CSCLI}" decisions list -o json
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output '1111:2222:3333:4444:5555:6666:7777:8888'

    # bouncer: getting all decision
    run docurl "/v1/decisions"
    assert_success
    run jq -r '.[].value' <(echo "$output")
    assert_success
    assert_output '1111:2222:3333:4444:5555:6666:7777:8888'

    # cscli: getting decisions for ip 1111:2222:3333:4444:5555:6666:7777:8888
    run "${CSCLI}" decisions list -i '1111:2222:3333:4444:5555:6666:7777:8888' -o json
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output '1111:2222:3333:4444:5555:6666:7777:8888'

    # bouncer: getting decisions for ip 1111:2222:3333:4444:5555:6666:7777:888
    run docurl '/v1/decisions?ip=1111:2222:3333:4444:5555:6666:7777:8888'
    assert_success
    run jq -r '.[].value' <(echo "$output")
    assert_success
    assert_output '1111:2222:3333:4444:5555:6666:7777:8888'

    # cscli: getting decisions for ip 1211:2222:3333:4444:5555:6666:7777:8888
    run "${CSCLI}" decisions list -i '1211:2222:3333:4444:5555:6666:7777:8888' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for ip 1211:2222:3333:4444:5555:6666:7777:888
    run docurl '/v1/decisions?ip=1211:2222:3333:4444:5555:6666:7777:8888'
    assert_success
    assert_output 'null'

    # cscli: getting decisions for ip 1111:2222:3333:4444:5555:6666:7777:8887
    run "${CSCLI}" decisions list -i '1111:2222:3333:4444:5555:6666:7777:8887' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for ip 1111:2222:3333:4444:5555:6666:7777:888
    run docurl '/v1/decisions?ip=1111:2222:3333:4444:5555:6666:7777:8887'
    assert_success
    assert_output 'null'

    # cscli: getting decisions for range 1111:2222:3333:4444:5555:6666:7777:8888/48
    run "${CSCLI}" decisions list -r '1111:2222:3333:4444:5555:6666:7777:8888/48' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for range 1111:2222:3333:4444:5555:6666:7777:8888/48
    run docurl '/v1/decisions?range=1111:2222:3333:4444:5555:6666:7777:8888/48'
    assert_success
    assert_output 'null'

    # cscli: getting decisions for ip/range in range 1111:2222:3333:4444:5555:6666:7777:8888/48
    run "${CSCLI}" decisions list -r '1111:2222:3333:4444:5555:6666:7777:8888/48' --contained -o json
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output '1111:2222:3333:4444:5555:6666:7777:8888'

    # bouncer: getting decisions for ip/range in 1111:2222:3333:4444:5555:6666:7777:8888/48
    run docurl '/v1/decisions?range=1111:2222:3333:4444:5555:6666:7777:8888/48&&contains=false'
    assert_success
    run jq -r '.[].value' <(echo "$output")
    assert_success
    assert_output '1111:2222:3333:4444:5555:6666:7777:8888'

    # cscli: getting decisions for range 1111:2222:3333:4444:5555:6666:7777:8888/64
    run "${CSCLI}" decisions list -r '1111:2222:3333:4444:5555:6666:7777:8888/64' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for range 1111:2222:3333:4444:5555:6666:7777:8888/64
    run docurl '/v1/decisions?range=1111:2222:3333:4444:5555:6666:7777:8888/64'
    assert_success
    assert_output 'null'

    # cscli: getting decisions for ip/range in 1111:2222:3333:4444:5555:6666:7777:8888/64
    run "${CSCLI}" decisions list -r '1111:2222:3333:4444:5555:6666:7777:8888/64' -o json --contained
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output '1111:2222:3333:4444:5555:6666:7777:8888'

    # bouncer: getting decisions for ip/range in 1111:2222:3333:4444:5555:6666:7777:8888/64
    run docurl '/v1/decisions?range=1111:2222:3333:4444:5555:6666:7777:8888/64&&contains=false'
    assert_success
    run jq -r '.[].value' <(echo "$output")
    assert_success
    assert_output '1111:2222:3333:4444:5555:6666:7777:8888'

    # cscli: adding decision for ip 1111:2222:3333:4444:5555:6666:7777:8889
    run "${CSCLI}" decisions add -i '1111:2222:3333:4444:5555:6666:7777:8889'
    assert_success
    assert_output --partial 'Decision successfully added'

    # cscli: deleting decision for ip 1111:2222:3333:4444:5555:6666:7777:8889
    run "${CSCLI}" decisions delete -i '1111:2222:3333:4444:5555:6666:7777:8889'
    assert_success
    assert_output --partial '1 decision(s) deleted'

    # cscli: getting decisions for ip 1111:2222:3333:4444:5555:6666:7777:8889 after delete
    run "${CSCLI}" decisions list -i '1111:2222:3333:4444:5555:6666:7777:8889' -o json
    assert_success
    assert_output 'null'

    # cscli: deleting decision for range 1111:2222:3333:4444:5555:6666:7777:8888/64
    run "${CSCLI}" decisions delete -r '1111:2222:3333:4444:5555:6666:7777:8888/64' --contained
    assert_success
    assert_output --partial '1 decision(s) deleted'

    # cscli: getting decisions for ip/range in 1111:2222:3333:4444:5555:6666:7777:8888/64 after delete
    run "${CSCLI}" decisions list -r '1111:2222:3333:4444:5555:6666:7777:8888/64' -o json --contained
    assert_success
    assert_output 'null'

    #
    # TEST IPV6 RANGE
    #

    # cscli: adding decision for range aaaa:2222:3333:4444::/64
    run "${CSCLI}" decisions add -r 'aaaa:2222:3333:4444::/64'
    assert_success
    assert_output --partial 'Decision successfully added'

    # cscli: getting all decision
    run "${CSCLI}" decisions list -o json
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output 'aaaa:2222:3333:4444::/64'

    # bouncer: getting all decision
    run docurl '/v1/decisions'
    assert_success
    run jq -r '.[].value' <(echo "$output")
    assert_success
    assert_output 'aaaa:2222:3333:4444::/64'

    # check ip within/out of range

    # cscli: getting decisions for ip aaaa:2222:3333:4444:5555:6666:7777:8888
    run "${CSCLI}" decisions list -i 'aaaa:2222:3333:4444:5555:6666:7777:8888' -o json
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output 'aaaa:2222:3333:4444::/64'

    # bouncer: getting decisions for ip aaaa:2222:3333:4444:5555:6666:7777:8888
    run docurl '/v1/decisions?ip=aaaa:2222:3333:4444:5555:6666:7777:8888'
    assert_success
    run jq -r '.[].value' <(echo "$output")
    assert_success
    assert_output 'aaaa:2222:3333:4444::/64'

    # cscli: getting decisions for ip aaaa:2222:3333:4445:5555:6666:7777:8888
    run "${CSCLI}" decisions list -i 'aaaa:2222:3333:4445:5555:6666:7777:8888' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for ip aaaa:2222:3333:4445:5555:6666:7777:8888
    run docurl '/v1/decisions?ip=aaaa:2222:3333:4445:5555:6666:7777:8888'
    assert_success
    assert_output 'null'

    # cscli: getting decisions for ip aaa1:2222:3333:4444:5555:6666:7777:8887
    run "${CSCLI}" decisions list -i 'aaa1:2222:3333:4444:5555:6666:7777:8887' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for ip aaa1:2222:3333:4444:5555:6666:7777:8887
    run docurl '/v1/decisions?ip=aaa1:2222:3333:4444:5555:6666:7777:8887'
    assert_success
    assert_output 'null'

    # check subrange within/out of range

    # cscli: getting decisions for range aaaa:2222:3333:4444:5555::/80
    run "${CSCLI}" decisions list -r 'aaaa:2222:3333:4444:5555::/80' -o json
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output 'aaaa:2222:3333:4444::/64'

    # bouncer: getting decisions for range aaaa:2222:3333:4444:5555::/80
    run docurl '/v1/decisions?range=aaaa:2222:3333:4444:5555::/80'
    assert_success
    run jq -r '.[].value' <(echo "$output")
    assert_success
    assert_output 'aaaa:2222:3333:4444::/64'

    # cscli: getting decisions for range aaaa:2222:3333:4441:5555::/80
    run "${CSCLI}" decisions list -r 'aaaa:2222:3333:4441:5555::/80' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for range aaaa:2222:3333:4441:5555::/80
    run docurl '/v1/decisions?range=aaaa:2222:3333:4441:5555::/80'
    assert_success
    assert_output 'null'

    # cscli: getting decisions for range aaa1:2222:3333:4444:5555::/80
    run "${CSCLI}" decisions list -r 'aaa1:2222:3333:4444:5555::/80' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for range aaa1:2222:3333:4444:5555::/80
    run docurl '/v1/decisions?range=aaa1:2222:3333:4444:5555::/80'
    assert_success
    assert_output 'null'

    # check outer range

    # cscli: getting decisions for range aaaa:2222:3333:4444:5555:6666:7777:8888/48
    run "${CSCLI}" decisions list -r 'aaaa:2222:3333:4444:5555:6666:7777:8888/48' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for range aaaa:2222:3333:4444:5555:6666:7777:8888/48
    run docurl '/v1/decisions?range=aaaa:2222:3333:4444:5555:6666:7777:8888/48'
    assert_success
    assert_output 'null'

    # cscli: getting decisions for ip/range in aaaa:2222:3333:4444:5555:6666:7777:8888/48
    run "${CSCLI}" decisions list -r 'aaaa:2222:3333:4444:5555:6666:7777:8888/48' -o json --contained
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output 'aaaa:2222:3333:4444::/64'

    # bouncer: getting decisions for ip/range in aaaa:2222:3333:4444:5555:6666:7777:8888/48
    run docurl '/v1/decisions?range=aaaa:2222:3333:4444:5555:6666:7777:8888/48&contains=false'
    assert_success
    run jq -r '.[].value' <(echo "$output")
    assert_success
    assert_output 'aaaa:2222:3333:4444::/64'

    # cscli: getting decisions for ip/range aaaa:2222:3333:4445:5555:6666:7777:8888/48
    run "${CSCLI}" decisions list -r 'aaaa:2222:3333:4445:5555:6666:7777:8888/48' -o json
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for ip/range in aaaa:2222:3333:4445:5555:6666:7777:8888/48
    run docurl '/v1/decisions?range=aaaa:2222:3333:4445:5555:6666:7777:8888/48'
    assert_success
    assert_output 'null'

    # bbbb:db8:: -> bbbb:db8:0000:0000:0000:7fff:ffff:ffff

    # cscli: adding decision for range bbbb:db8::/81
    run "${CSCLI}" decisions add -r 'bbbb:db8::/81'
    assert_success
    assert_output --partial 'Decision successfully added'

    # cscli: getting decisions for ip bbbb:db8:0000:0000:0000:6fff:ffff:ffff
    run "${CSCLI}" decisions list -o json -i 'bbbb:db8:0000:0000:0000:6fff:ffff:ffff'
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output 'bbbb:db8::/81'

    # bouncer: getting decisions for ip in bbbb:db8:0000:0000:0000:6fff:ffff:ffff
    run docurl '/v1/decisions?ip=bbbb:db8:0000:0000:0000:6fff:ffff:ffff'
    assert_success
    run jq -r '.[].value' <(echo "$output")
    assert_success
    assert_output 'bbbb:db8::/81'

    # cscli: getting decisions for ip bbbb:db8:0000:0000:0000:8fff:ffff:ffff
    run "${CSCLI}" decisions list -o json -i 'bbbb:db8:0000:0000:0000:8fff:ffff:ffff'
    assert_success
    assert_output 'null'

    # bouncer: getting decisions for ip in bbbb:db8:0000:0000:0000:8fff:ffff:ffff
    run docurl '/v1/decisions?ip=bbbb:db8:0000:0000:0000:8fff:ffff:ffff'
    assert_success
    assert_output 'null'

    # cscli: deleting decision for range aaaa:2222:3333:4444:5555:6666:7777:8888/48
    run "${CSCLI}" decisions delete -r 'aaaa:2222:3333:4444:5555:6666:7777:8888/48' --contained
    assert_success
    assert_output --partial '1 decision(s) deleted'

    # cscli: getting decisions for range aaaa:2222:3333:4444::/64 after delete
    run "${CSCLI}" decisions list -o json -r 'aaaa:2222:3333:4444::/64'
    assert_success
    assert_output 'null'

    # cscli: adding decision for ip bbbb:db8:0000:0000:0000:8fff:ffff:ffff
    run "${CSCLI}" decisions add -i 'bbbb:db8:0000:0000:0000:8fff:ffff:ffff'
    assert_success
    assert_output --partial 'Decision successfully added'

    # cscli: adding decision for ip bbbb:db8:0000:0000:0000:6fff:ffff:ffff
    run "${CSCLI}" decisions add -i 'bbbb:db8:0000:0000:0000:6fff:ffff:ffff'
    assert_success
    assert_output --partial 'Decision successfully added'

    # cscli: deleting decisions for range bbbb:db8::/81
    run "${CSCLI}" decisions delete -r 'bbbb:db8::/81' --contained
    assert_success
    assert_output --partial '2 decision(s) deleted'

    # cscli: getting all decisions
    run "${CSCLI}" decisions list -o json
    assert_success
    run jq -r '.[].decisions[0].value' <(echo "$output")
    assert_success
    assert_output 'bbbb:db8:0000:0000:0000:8fff:ffff:ffff'
}
