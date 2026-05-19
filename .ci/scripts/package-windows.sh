#!/bin/bash
set -e -u -o pipefail

python3 -m venv env
. env/bin/activate
pip install pynacl==1.4.0 pygithub==1.55

VERSION=$(git describe --tags --always --match "[0-9][0-9][0-9][0-9].*.*")
echo $VERSION

export TARGET_OS=windows
# This controls the directory the built artifacts go into
export BUILT_ARTIFACT_DIR=artifacts/
export FINAL_ARTIFACT_DIR=artifacts/
mkdir -p $BUILT_ARTIFACT_DIR
mkdir -p $FINAL_ARTIFACT_DIR
windowsArchs=("amd64" "386")
for arch in ${windowsArchs[@]}; do
    export TARGET_ARCH=$arch
    # Copy .exe from artifacts directory
    cp $BUILT_ARTIFACT_DIR/cinatunnel-windows-$arch.exe ./cinatunnel.exe
    make cinatunnel-msi
    # Copy msi into final directory
    mv cinatunnel-$VERSION-$arch.msi $FINAL_ARTIFACT_DIR/cinatunnel-windows-$arch.msi
done
