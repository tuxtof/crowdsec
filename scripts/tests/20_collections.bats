#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
. "$LIB/wrap-init.sh"

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME} .bats)" >&3
  "$SYSTEMCTL" start crowdsec || "$SYSTEMCTL" restart crowdsec
#  run cscli collections install crowdsecurity/sshd
}

teardown_file() {
:
}

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
}

#----------

@test "we can list collections" {
  run cscli collections list
  [ $status -eq 0 ]
}

@test "there are 2 collections" {
  run cscli collections list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq '. | length') -eq 2 ]]
}

@test "cannot install a collection as regular user" {
  # XXX -o human returns two items, -o json and -o raw return only errors
  run --separate-stderr cscli collections install crowdsecurity/mysql -o json
  [ $status -eq 1 ]
  [[ $(echo $stderr | jq -r '.level') = "fatal" ]]
  [[ $(echo $stderr | jq '.msg') =~ "error while downloading crowdsecurity/mysql" ]]
  [[ $(echo $stderr | jq '.msg') =~ "permission denied" ]]
}

@test "can install a collection as root" {
  run sudo cscli collections install crowdsecurity/mysql -o human
  [ $status -eq 0 ]
  [[ "$output" =~ "Enabled crowdsecurity/mysql" ]]
}

@test "there are now 3 collections" {
  run cscli collections list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq '. | length') -eq 3 ]]
}

@test "cannot remove a collection as regular user" {
  run --separate-stderr cscli collections remove crowdsecurity/mysql -o json
  [ $status -eq 1 ]
  [[ $(echo $stderr | jq -r '.level') = "fatal" ]]
  [[ $(echo $stderr | jq '.msg') =~ "unable to disable crowdsecurity/mysql" ]]
  [[ $(echo $stderr | jq '.msg') =~ "permission denied" ]]
}

@test "can remove a collection as root" {
  run sudo cscli collections remove crowdsecurity/mysql -o human
  [ $status -eq 0 ]
  [[ "$output" =~ "Removed symlink [crowdsecurity/mysql]" ]]
}

@test "cannot remove a collection twice" {
  run --separate-stderr sudo cscli collections remove crowdsecurity/mysql -o json
  [ $status -eq 1 ]
  [[ $(echo $stderr | jq -r '.level') = "fatal" ]]
  [[ $(echo $stderr | jq '.msg') =~ "unable to disable crowdsecurity/mysql" ]]
  [[ $(echo $stderr | jq '.msg') =~ "doesn't exist" ]]
}

@test "there are now 2 collections again" {
  run cscli collections list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq '. | length') -eq 2 ]]
}

