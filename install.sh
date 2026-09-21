#!/bin/bash
# Installer for igmusic - Instagram Music Activation for x-ui panel.
#   sudo bash install.sh
# Copies the `igmusic` CLI to /usr/local/sbin, checks prerequisites, and (if the
# IGMUSIC outbound is present) adds the static region-check routing rule.
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
  echo "==> applying the static rule"
  igmusic install
else
  echo
  echo "Add an outbound tagged 'IGMUSIC' with a US egress IP in the x-ui panel"
  echo "(any protocol: socks/http proxy, vless, vmess, trojan, shadowsocks, wireguard),"
  echo "then run:  sudo igmusic install"
fi
