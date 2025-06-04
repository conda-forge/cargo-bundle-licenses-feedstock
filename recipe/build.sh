#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit


export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_LTO=fat

export CARGO_HOME="$BUILD_PREFIX/cargo"
mkdir $CARGO_HOME

if [[ "$c_compiler" == "clang" ]]; then
  echo "-L$BUILD_PREFIX/lib -Wl,-rpath,$BUILD_PREFIX/lib" > $BUILD_PREFIX/bin/$BUILD.cfg
  echo "-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib" > $BUILD_PREFIX/bin/$HOST.cfg
fi

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

echo $CONDA_RUST_HOST, $CONDA_RUST_TARGET

export RUSTFLAGS=$CARGO_BUILD_RUSTFLAGS

# build statically linked binary with Rust
cargo auditable install --no-track --verbose --locked --root "$PREFIX" --path .
