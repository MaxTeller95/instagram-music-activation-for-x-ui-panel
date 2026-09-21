#!/bin/bash
# Installer for igmusic - Instagram Music Activation for x-ui panel.
#
# From a clone:   sudo bash install.sh
# One-liner:      sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/MaxTeller95/instagram-music-activation-for-x-ui-panel/master/install.sh)"
#                 (the one-liner needs the repo to be public)
#
# Copies the `igmusic` CLI to /usr/local/sbin, checks prerequisites, and (if the
# IGMUSIC outbound is present) adds the static region-check routing rule.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run as root: sudo bash install.sh"; exit 1; }

RAW="https://raw.githubusercontent.com/MaxTeller95/instagram-music-activation-for-x-ui-panel/master"
HERE="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"

if [ -n "${HERE:-}" ] && [ -f "$HERE/igmusic" ]; then
  # running from a git clone
  install -m 755 "$HERE/igmusic" /usr/local/sbin/igmusic
else
  # running standalone (curl | bash): fetch the CLI from the repo
  echo "fetching igmusic ..."
  curl -fsSL "$RAW/igmusic" -o /usr/local/sbin/igmusic \
    || { echo "could not download igmusic - is the repo public? otherwise use: git clone <url>"; exit 1; }
  chmod 755 /usr/local/sbin/igmusic
fi
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
