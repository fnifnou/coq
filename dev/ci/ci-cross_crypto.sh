#!/usr/bin/env bash

set -e

ci_dir="$(dirname "$0")"
. "${ci_dir}/ci-common.sh"

WITH_SUBMODULES=1
git_download cross_crypto

( cd "${CI_BUILD_DIR}/cross_crypto"
  make
)
