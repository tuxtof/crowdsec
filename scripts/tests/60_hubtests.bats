#!/usr/bin/env bats

LIB="$(dirname "$BATS_TEST_FILENAME")/lib"
#shellcheck source=../lib/wrap-init.sh
. "$LIB/wrap-init.sh"

setup_file() {
  echo "# --- $(basename ${BATS_TEST_FILENAME} .bats)" >&3
  "$SYSTEMCTL" start crowdsec || "$SYSTEMCTL" restart crowdsec
}

teardown_file() {
  # "$SYSTEMCTL" stop crowdsec
  :
}

#----------

@test "hub tests" {
  repodir=$(mktemp -d)
  run git clone --depth 1 https://github.com/crowdsecurity/hub.git "${repodir}"
  [ $status -eq 0 ]
  pushd "${repodir}"
  run cscli hubtest run --all --clean
  # needed to see what's broken
  echo "$output"
  [ $status -eq 0 ]
  popd
  rm -rf -- "${repodir}"
}

