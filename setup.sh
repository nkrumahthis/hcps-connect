#!/usr/bin/env bash
# Joins this Linux machine to the HCPS private network (Tailscale).
#
# Usage:
#   sudo bash setup.sh hcps              # the HCPS server
#   sudo bash setup.sh stjude            # St. Jude's billing server
#   sudo bash setup.sh hcps tskey-...    # join with a pre-made auth key instead of a login link
#
# Safe to run again: it re-applies the same settings.
set -euo pipefail

ROLE="${1:-}"
AUTH_KEY="${2:-${TS_AUTHKEY:-}}"

case "$ROLE" in
  hcps)   TS_HOSTNAME="hcps-server";    TAG="tag:hcps" ;;
  stjude) TS_HOSTNAME="stjude-billing"; TAG="tag:stjude" ;;
  *)
    echo "Say which machine this is:" >&2
    echo "  sudo bash setup.sh hcps      (the HCPS server)" >&2
    echo "  sudo bash setup.sh stjude    (St. Jude's billing server)" >&2
    exit 1 ;;
esac

if [ "$(uname -s)" != "Linux" ]; then
  echo "This script is for Linux. On Windows or macOS, install Tailscale from https://tailscale.com/download" >&2
  exit 1
fi
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run it with sudo:  sudo bash setup.sh $ROLE" >&2
  exit 1
fi

step() { printf '\n==> %s\n' "$*"; }

step "Installing Tailscale"
if command -v tailscale >/dev/null 2>&1; then
  echo "Already installed: $(tailscale version | head -1)"
else
  curl -fsSL https://tailscale.com/install.sh | sh
fi
systemctl enable --now tailscaled

# Tailscale's access rules decide who can reach this machine; let traffic
# that arrives over the tunnel through the local firewall so they apply.
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  step "Allowing tunnel traffic through the firewall (ufw)"
  ufw allow in on tailscale0 comment "HCPS private network (Tailscale)"
fi

UP_ARGS=(--reset --hostname="$TS_HOSTNAME" --advertise-tags="$TAG")
if [ "$ROLE" = "hcps" ]; then
  UP_ARGS+=(--ssh)   # lets the HCPS admin log in over the tunnel without a password
fi

step "Connecting to the HCPS private network"
if [ -n "$AUTH_KEY" ]; then
  tailscale up "${UP_ARGS[@]}" --auth-key="$AUTH_KEY"
else
  echo "A login link will appear below."
  echo "Send that link to Nkrumah and leave this window open until it says Success."
  echo
  tailscale up "${UP_ARGS[@]}"
fi

step "Done"
echo "Machine name: $TS_HOSTNAME"
echo "Private address: $(tailscale ip -4)"
echo
echo "Send the private address above to Nkrumah."
