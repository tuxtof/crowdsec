#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
. "$LIB/wrap-init.sh"

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME} .bats)" >&3
  "$SYSTEMCTL" start crowdsec || "$SYSTEMCTL" restart crowdsec
}

#-------

@test "cscli version" {
  run cscli version
  [ $status -eq 0 ]
  [[ "$output" =~ "version:" ]]
  [[ "$output" =~ "Codename:" ]]
  [[ "$output" =~ "BuildDate:" ]]
  [[ "$output" =~ "GoVersion:" ]]
  [[ "$output" =~ "Constraint_parser:" ]]
  [[ "$output" =~ "Constraint_scenario:" ]]
  [[ "$output" =~ "Constraint_api:" ]]
  [[ "$output" =~ "Constraint_acquis:" ]]
}

@test "cscli alerts list: at startup returns at least one entry: community pull" {
  output=$(sudo cscli alerts list -o json | jq -e '. | length')
  [[ $output -ge 1 ]]
}

@test "cscli capi status" {
  run --separate-stderr sudo cscli capi status
  [ $status -eq 0 ]
  [[ "$stderr" =~ "Loaded credentials from" ]]
  [[ "$stderr" =~ "Trying to authenticate with username" ]]
  [[ "$stderr" =~ " on https://api.crowdsec.net/" ]]
  [[ "$stderr" =~ "You can successfully interact with Central API (CAPI)" ]]
}

@test "cscli config show" {
  run cscli config show
  [ $status -eq 0 ]
  [[ "$output" =~ "Global:" ]]
  [[ "$output" =~ "Crowdsec:" ]]
  [[ "$output" =~ "cscli:" ]]
  [[ "$output" =~ "Local API Server:" ]]
}

@test "cscli config show -o json" {
  run cscli config show -o human
  [ $status -eq 0 ]
  # TODO
}

@test "cscli config show -o raw" {
  run cscli config show -o human
  [ $status -eq 0 ]
  # TODO
}

@test "cscli config show --key" {
  run sudo cscli config show --key Config.API.Server.ListenURI
  [ $status -eq 0 ]
  [ "$output" = "127.0.0.1:8080" ]
}

@test "cscli config backup" {
  tempdir=$(mktemp -u)
  run sudo cscli config backup "${tempdir}"
  [ $status -eq 0 ]
  [[ "$output" =~ "Starting configuration backup" ]]
  run --separate-stderr sudo cscli config backup "${tempdir}"
  [[ $status -eq 1 ]]
  [[ "$stderr" =~ "Failed to backup configurations" ]]
  [[ "$stderr" =~ "file exists" ]]
  sudo rm -rf -- "${tempdir}"
}

@test "cscli lapi status" {
  run --separate-stderr sudo cscli lapi status
  [ $status -eq 0 ]
  [[ "$stderr" =~ "Loaded credentials from" ]]
  [[ "$stderr" =~ "Trying to authenticate with username" ]]
  [[ "$stderr" =~ " on http://127.0.0.1:8080/" ]]
  [[ "$stderr" =~ "You can successfully interact with Local API (LAPI)" ]]
}

@test "cscli metrics" {
  run --separate-stderr sudo cscli metrics
  [ $status -eq 0 ]
  [[ "$stderr" =~ "Local Api Metrics:" ]]
  [[ "$stderr" =~ "Local Api Machines Metrics:" ]]
  [[ "$output" =~ "ROUTE" ]]
  [[ "$output" =~ "MACHINE" ]]
}
