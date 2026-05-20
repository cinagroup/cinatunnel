#!/bin/bash
set -eu
ln -sf /usr/bin/cinatunnel /usr/local/bin/cinatunnel
mkdir -p /usr/local/etc/cinatunnel/
touch /usr/local/etc/cinatunnel/.installedFromPackageManager || true
