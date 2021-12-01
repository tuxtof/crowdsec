#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
. "$LIB/wrap-init.sh"

fake_log() {
  for i in $(seq 1 10) ; do 
    echo "$(LC_ALL=C date '+%b %d %H:%M:%S ')"'sd-126005 sshd[12422]: Invalid user netflix from 1.1.1.174 port 35424'
  done;
}

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME} .bats)" >&3
  "$SYSTEMCTL" start crowdsec || "$SYSTEMCTL" restart crowdsec
  # theses is already present.
  # if we add them here anyway, should we remove in teardown or not?
  #sudo cscli collections install crowdsecurity/sshd
  #sudo cscli scenarios install crowdsecurity/ssh-bf
  #${SYSTEMCTL} reload crowdsec
  sudo cscli decisions delete --all
  sudo cscli simulation disable --global
  "$SYSTEMCTL" reload crowdsec
  fake_log | sudo crowdsec -dsn file:///dev/fd/0 -type syslog -no-api
}

teardown_file() {
  sudo cscli decisions delete --all
  sudo cscli simulation disable --global
  # XXX
  # "$SYSTEMCTL" stop crowdsec
}

#----------

@test "we have one decision" {
  run sudo cscli decisions list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq '. | length') -eq 1 ]]
}

@test "1.1.1.174 has been banned (exact)" {
  run sudo cscli decisions list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq -r '.[].decisions[0].value') = "1.1.1.174" ]]
}

@test "decision has simulated == false (exact)" {
  run sudo cscli decisions list -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq -r '.[].decisions[0].simulated') = "false" ]]
}

@test "simulated scenario, listing non-simulated: expect no decision" {
  sudo cscli decisions delete --all
  sudo cscli simulation enable crowdsecurity/ssh-bf
  fake_log | sudo crowdsec -dsn file:///dev/fd/0 -type syslog -no-api
  run sudo cscli decisions list --no-simu -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq -r '.') = "null" ]]
}

@test "global simulation, listing non-simulated: expect no decision" {
  sudo cscli decisions delete --all
  sudo cscli simulation disable crowdsecurity/ssh-bf
  sudo cscli simulation enable --global
  fake_log | sudo crowdsec -dsn file:///dev/fd/0 -type syslog -no-api
  run sudo cscli decisions list --no-simu -o json
  [ $status -eq 0 ]
  [[ $(echo $output | jq -r '.') = "null" ]]
}

