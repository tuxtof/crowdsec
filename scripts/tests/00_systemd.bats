#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
. "$LIB/wrap-init.sh"

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME} .bats)" >&3
  "$SYSTEMCTL" start crowdsec || "$SYSTEMCTL" restart crowdsec
}

teardown_file() {
  "$SYSTEMCTL" stop crowdsec
}

#
# "systemctl status" return codes
#
# https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Core-generic/LSB-Core-generic.html#INISCRPTACT
# 
# If the status action is requested, the init script will return the following exit status codes.
# 
# 0        program is running or service is OK
# 1        program is dead and /var/run pid file exists
# 2        program is dead and /var/lock lock file exists
# 3        program is not running
# 4        program or service status is unknown
# 5-99     reserved for future LSB use
# 100-149  reserved for distribution use
# 150-199  reserved for application use
# 200-254  reserved

#-------

@test "systemctl status shows an active process" {
  run "$SYSTEMCTL" status crowdsec
  [ $status -eq 0 ]
  [[ "$output" =~ "active (running)" ]]
}

@test "crowdsec process is running" {
  run pgrep -x crowdsec
  [ $status -eq 0 ]
}

#-------

@test "systemctl can stop crowdsec" {
  run "$SYSTEMCTL" stop crowdsec
  [ $status -eq 0 ]
}

@test "systemctl status shows an inactive process" {
  run "$SYSTEMCTL" status crowdsec
  [ $status -eq 3 ]
  [[ "$output" =~ "inactive (dead)" ]]
}

@test "crowdsec process is not running" {
  run pgrep -x crowdsec
  [ $status -eq 1 ]
}

#-------

@test "systemctl can start crowdsec" {
  run "$SYSTEMCTL" start crowdsec
  [ $status -eq 0 ]
  [[ "$output" = "" ]]
}

@test "crowdsec process is running again" {
  run pgrep -x crowdsec
  [ $status -eq 0 ]
}

#-------

@test "systemctl can restart crowdsec" {
  run "$SYSTEMCTL" restart crowdsec
  [ $status -eq 0 ]
}

@test "crowdsec process is running after restart" {
  run pgrep -x crowdsec
  [ $status -eq 0 ]
}

