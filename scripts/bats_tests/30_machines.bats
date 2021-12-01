#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
. "$LIB/wrap-init.sh"

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME})" >&3
  "$SYSTEMCTL" start crowdsec
}

teardown_file() {
:
}

#----------

@test "can't list machines as regular user" {
  run --separate-stderr cscli machines list -o json
  [ $status -eq 1 ]
  [[ $(echo $stderr | jq --slurp -r '.[0].level') = "error" ]]
  [[ $(echo $stderr | jq --slurp -r '.[0].msg') =~ "failed to read api server credentials" ]]
}

@test "we have exactly one machine, localhost" {
  run sudo cscli machines list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq '. | length') -eq 1 ]]
  [[ $(echo $output | jq -r '.[0].ipAddress') = "127.0.0.1" ]]
  [[ $(echo $output | jq -r '.[0].isValidated') = "true" ]]
}

@test "add a new machine" {
  run sudo cscli machines add -a -f /dev/null CiTestMachine -o human
  [ $status -eq 0 ]
  echo $output
  [[ "$output" =~ "Machine 'CiTestMachine' successfully added to the local API" ]]
  [[ "$output" =~ "API credentials dumped to '/dev/null'" ]]
}

@test "we now have two machines" {
  run sudo cscli machines list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq '. | length') -eq 2 ]]
  [[ $(echo $output | jq -r '.[-1].machineId') = "CiTestMachine" ]]
  [[ $(echo $output | jq -r '.[0].isValidated') = "true" ]]
}

@test "delete the test machine" {
  run sudo cscli machines delete CiTestMachine -o human
  [ $status -eq 0 ]
  echo $output
  [[ "$output" =~ "machine 'CiTestMachine' deleted successfully" ]]
}

@test "we now have one machine again" {
  run sudo cscli machines list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq '. | length') -eq 1 ]]
}

@test "register a machine" {
  run sudo cscli lapi register --machine CiTestMachineRegister -f /dev/null -o human
  [ $status -eq 0 ]
  [[ "$output" =~ "Successfully registered to Local API (LAPI)" ]]
  [[ "$output" =~ "Local API credentials dumped to '/dev/null'" ]]
}

@test "the machine is not validated yet" {
  run sudo cscli machines list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq -r '.[-1].isValidated') = "null" ]]
}

@test "validate the machine" {
  run sudo cscli machines validate CiTestMachineRegister -o human
  [ $status -eq 0 ]
  [[ "$output" =~ "machine 'CiTestMachineRegister' validated" ]]
  # TODO
  #[[ "$output" =~ "machine 'CiTestMachineRegister' validated successfully" ]]
}

@test "the machine is now validated" {
  run sudo cscli machines list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq -r '.[-1].isValidated') = "true" ]]
}

@test "delete the test machine again" {
  run sudo cscli machines delete CiTestMachineRegister -o human
  [ $status -eq 0 ]
  echo $output
  [[ "$output" =~ "machine 'CiTestMachineRegister' deleted successfully" ]]
}

@test "we now have one machine, again again" {
  run sudo cscli machines list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq '. | length') -eq 1 ]]
}

