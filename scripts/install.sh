#!/bin/bash
# NoPulse-HUB — apply configuration files on Raspberry Pi
# Run with: sudo bash scripts/install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$REPO_DIR/configs"

echo "=== NoPulse-HUB config installer ==="

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/install.sh"
  exit 1
fi

install -d /etc/netplan
install -d /etc/unbound/unbound.conf.d
install -d /etc/ssh/sshd_config.d
install -d /etc/wireguard

cp "$CONFIG_DIR/netplan-network.yaml" /etc/netplan/01-nopulse.yaml
grep -q "NO-PULSE HUB" /etc/sysctl.conf 2>/dev/null || cat "$CONFIG_DIR/sysctl.conf" >> /etc/sysctl.conf
cp "$CONFIG_DIR/nftables.conf" /etc/nftables.conf
cp "$CONFIG_DIR/unbound.conf" /etc/unbound/unbound.conf.d/nopulse.conf
cp "$CONFIG_DIR/sshd_config" /etc/ssh/sshd_config.d/nopulse.conf

if [[ -f /etc/wireguard/wg0.conf ]]; then
  echo "Keeping existing /etc/wireguard/wg0.conf (contains private key)"
else
  cp "$CONFIG_DIR/wireguard-wg0.conf" /etc/wireguard/wg0.conf
  chmod 600 /etc/wireguard/wg0.conf
  echo "Edit /etc/wireguard/wg0.conf and add your WireGuard private key before enabling VPN"
fi

echo "Applying netplan..."
netplan apply

echo "Applying sysctl..."
sysctl -p

echo "Enabling services..."
systemctl enable nftables
systemctl restart nftables || true
systemctl restart ssh || true
systemctl restart unbound || true

echo ""
echo "Done. Next steps:"
echo "  1. Set WiFi PSK in /etc/netplan/01-nopulse.yaml"
echo "  2. Add WireGuard private key to /etc/wireguard/wg0.conf"
echo "  3. Install Pi-hole and DNSCrypt-proxy (see README)"
echo "  4. sudo systemctl enable --now wg-quick@wg0"
echo "  5. Test kill-switch: stop WireGuard and confirm no traffic leak"
