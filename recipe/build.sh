#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

export CARGO_HOME="$BUILD_PREFIX/cargo"
mkdir $CARGO_HOME

(
  # Needed to bootstrap itself into the conda ecosystem
  unset CARGO_BUILD_TARGET
  export CARGO_BUILD_RUSTFLAGS=$(echo $CARGO_BUILD_RUSTFLAGS | sed "s@$PREFIX@$BUILD_PREFIX@g")
  export RUSTFLAGS=$CARGO_BUILD_RUSTFLAGS
  export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig
  unset MACOSX_DEPLOYMENT_TARGET
  unset CFLAGS
  unset CPPFLAGS
  unset LDFLAGS
  unset PREFIX
  cargo install --verbose cargo-bundle-licenses
  # Check that all downstream libraries licenses are present
  export PATH=$CARGO_HOME/bin:$PATH
  cargo bundle-licenses --format yaml --output CI.THIRDPARTY.yml --previous THIRDPARTY.yml --check-previous
)

export RUSTFLAGS=$CARGO_BUILD_RUSTFLAGS

# build statically linked binary with Rust
cargo install --verbose --locked --root "$PREFIX" --path .

# strip debug symbols
"$STRIP" "$PREFIX/bin/cargo-bundle-licenses"

# remove extra build file
rm -f "${PREFIX}/.crates.toml"
