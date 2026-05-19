#!/bin/bash
set -e -u -o pipefail
VERSION=$(git describe --tags --always --match "[0-9][0-9][0-9][0-9].*.*")
echo $VERSION

# This controls the directory the built artifacts go into
export ARTIFACT_DIR=artifacts/
mkdir -p $ARTIFACT_DIR

arch=("amd64")
export TARGET_ARCH=$arch
export TARGET_OS=linux
export FIPS=true
# For BoringCrypto to link, we need CGO enabled. Otherwise compilation fails.
export CGO_ENABLED=1

make cinatunnel-deb
mv cinatunnel-fips\_$VERSION\_$arch.deb $ARTIFACT_DIR/cinatunnel-fips-linux-$arch.deb

# rpm packages invert the - and _ and use x86_64 instead of amd64.
RPMVERSION=$(echo $VERSION | sed -r 's/-/_/g')
RPMARCH="x86_64"
make cinatunnel-rpm
mv cinatunnel-fips-$RPMVERSION-1.$RPMARCH.rpm $ARTIFACT_DIR/cinatunnel-fips-linux-$RPMARCH.rpm

# finally move the linux binary as well.
mv ./cinatunnel $ARTIFACT_DIR/cinatunnel-fips-linux-$arch
