#!/bin/bash
# Installer for igmusic - Instagram Music Activation for x-ui panel.
#   sudo bash install.sh
# Copies the `igmusic` CLI to /usr/local/sbin, checks prerequisites, and (if the
# residential outbound is present) enables the automatic refresh timer.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run as root: sudo bash install.sh"; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)/igmusic"
[ -f "$SRC" ] || { echo "igmusic not found next to install.sh"; exit 1; }

install -m 755 "$SRC" /usr/local/sbin/igmusic
echo "installed /usr/local/sbin/igmusic"

echo
echo "==> checking prerequisites"
if igmusic check; then
  echo
  echo "==> enabling automatic activation"
  igmusic install
else
  echo
  echo "Add a SOCKS outbound tagged 'residental' in the x-ui panel, then run:"
  echo "    sudo igmusic install"
fi
