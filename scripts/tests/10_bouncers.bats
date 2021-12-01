#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
. "$LIB/wrap-init.sh"

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME} .bats)" >&3
  "$SYSTEMCTL" start crowdsec
  # TODO remove all the bouncers?
}

teardown_file() {
:
  # TODO remove all the bouncers?
}

#----------

@test "there are 0 bouncers" {
  run sudo cscli bouncers list -o json
  [ $status -eq 0 ]
  [[ "$output" = "[]" ]]
}

@test "we can add one bouncer" {
  run sudo cscli bouncers add ciTestBouncer
  [ $status -eq 0 ]
  [[ "$output" =~ "Api key for 'ciTestBouncer':" ]]
}

@test "we can't add the same bouncer twice" {
  run --separate-stderr sudo cscli bouncers add ciTestBouncer -o json
  # XXX should this be 1 ?
  [ $status -eq 0 ]
  [[ $(echo $stderr | jq -r '.level') = "error" ]]
  [[ $(echo $stderr | jq -r '.msg') = "unable to create bouncer: bouncer ciTestBouncer already exists" ]]
}

@test "we have one bouncer" {
  run sudo cscli bouncers list -o json
  [[ $(echo $output | jq '. | length') -eq 1 ]]
}

@test "delete the bouncer" {
  run sudo cscli bouncers delete ciTestBouncer
  [ $status -eq 0 ]
}

@test "we have 0 bouncers" {
  run sudo cscli bouncers list -o json
  [[ $(echo $output | jq '. | length') -eq 0 ]]
}

