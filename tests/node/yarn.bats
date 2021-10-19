#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

YARN_CACHE_DIR=/opt/buildhome/.yarn_cache

# So that we can speed up the `run_yarn` function and not require new yarn installs for tests
YARN_DEFAULT_VERSION=1.22.10

setup() {
  TMP_DIR=$(setup_tmp_dir)
  set_fixture_as_repo 'simple-node' "$TMP_DIR"

  # Load functions
  load '../../run-build-functions.sh'

  source_nvm
}

teardown() {
  rm -rf "$TMP_DIR"
  # Return to original dir
  cd - || return
}

@test 'run_yarn sets up new yarn version if different from the one installed, installs deps and creates cache dir' {
  local newYarnVersion=1.21.0
  run run_yarn $newYarnVersion
  assert_success
  assert_output --partial "Installing yarn at version $newYarnVersion"
  assert_dir_exist $YARN_CACHE_DIR

  # The cache dir is actually being used
  assert_dir_exist "$YARN_CACHE_DIR/v6"
}

@test 'run_yarn allows passing multiple yarn flags via YARN_FLAGS env var to yarn install' {
  YARN_FLAGS="--no-default-rc --verbose"
  run run_yarn $YARN_DEFAULT_VERSION

  assert_success
  # The flags we pass on both produce verbose output and omit any reference to checking for configuration files
  assert_output --partial "verbose"
  refute_output --partial "Checking for configuration file"
}

@test 'run_yarn does not allow setting --cache-folder via YARN_FLAGS' {
  local tmpCacheDir="./local-cache"

  YARN_FLAGS="--no-default-rc --verbose --cache-folder $tmpCacheDir"
  run run_yarn $YARN_DEFAULT_VERSION

  assert_success

  # The cache dir is actually being used
  assert_dir_exist "$YARN_CACHE_DIR/v6"
  assert_dir_not_exist "$tmpCacheDir"
}