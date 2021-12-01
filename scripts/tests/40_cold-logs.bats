#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
. "$LIB/wrap-init.sh"

fake_log() {
  for i in $(seq 1 6) ; do 
    echo "$(LC_ALL=C date '+%b %d %H:%M:%S ')"'sd-126005 sshd[12422]: Invalid user netflix from 1.1.1.172 port 35424'
  done;
}

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME} .bats)" >&3
  "$SYSTEMCTL" start crowdsec
  # this is already present.
  # if we add it here anyway, should we remove in teardown or not?
  #sudo cscli collections install crowdsecurity/sshd
  #${SYSTEMCTL} reload crowdsec
  sudo cscli decisions delete --all
  fake_log | sudo crowdsec -dsn file:///dev/fd/0 -type syslog -no-api
}

teardown_file() {
  sudo cscli decisions delete --all
}

#----------

@test "we have one decision" {
  run sudo cscli decisions list -o json
  [ $status -eq 0 ]
  [[ $(echo "$output" | jq '. | length') -eq 1 ]]
}

@test "1.1.1.172 has been banned" {
  run sudo cscli decisions list -o json
  [ $status -eq 0 ]
  [[ $(echo "$output" | jq -r '.[].decisions[0].value') = "1.1.1.172" ]]
}

@test "1.1.1.172 has been banned (range/contained: -r 1.1.1.0/24 --contained)" {
  run sudo cscli decisions list -r 1.1.1.0/24 --contained -o json
  [ $status -eq 0 ]
  [[ $(echo "$output" | jq -r '.[].decisions[0].value') = "1.1.1.172" ]]
}

@test "1.1.1.172 has not been banned (range/NOT-contained: -r 1.1.2.0/24)" {
  run sudo cscli decisions list -r 1.1.2.0/24 -o json
  [ $status -eq 0 ]
  [[ $(echo "$output" | jq -r '.') = "null" ]]
}

@test "1.1.1.172 has been banned (exact: -i 1.1.1.172)" {
  run sudo cscli decisions list -i 1.1.1.172 -o json
  [ $status -eq 0 ]
  [[ $(echo "$output" | jq -r '.[].decisions[0].value') = "1.1.1.172" ]]
}

@test "1.1.1.173 has not been banned (exact: -i 1.1.1.173)" {
  run sudo cscli decisions list -i 1.1.1.173 -o json
  [ $status -eq 0 ]
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
