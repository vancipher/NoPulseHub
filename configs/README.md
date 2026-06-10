# Configuration Files

Complete configuration files from the [NoPulse-HUB Cyber X project page](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub).

The live deployment runs on **Raspberry Pi 3** hardware. This directory contains the documented configs recovered from the official project write-up.

## Install paths on Raspberry Pi

| File in repo | Target path on Pi |
|---|---|
| `netplan-network.yaml` | `/etc/netplan/01-nopulse.yaml` |
| `sysctl.conf` | Append to `/etc/sysctl.conf`, then `sudo sysctl -p` |
| `nftables.conf` | `/etc/nftables.conf` |
| `unbound.conf` | `/etc/unbound/unbound.conf.d/nopulse.conf` |
| `sshd_config` | `/etc/ssh/sshd_config.d/nopulse.conf` |
| `wireguard-wg0.conf` | `/etc/wireguard/wg0.conf` |

## Required services

```bash
sudo apt update
sudo apt install -y nftables fail2ban wireguard unbound
# Pi-hole and DNSCrypt-proxy: install per their official guides
```

## Apply configuration

```bash
sudo cp netplan-network.yaml /etc/netplan/01-nopulse.yaml
sudo cat sysctl.conf >> /etc/sysctl.conf
sudo cp nftables.conf /etc/nftables.conf
sudo cp unbound.conf /etc/unbound/unbound.conf.d/nopulse.conf
sudo cp sshd_config /etc/ssh/sshd_config.d/nopulse.conf
sudo cp wireguard-wg0.conf /etc/wireguard/wg0.conf

sudo netplan apply
sudo sysctl -p
sudo systemctl enable --now nftables fail2ban wg-quick@wg0
sudo systemctl restart ssh unbound
```

## Before going live

1. Set your WireGuard **private key** in `wireguard-wg0.conf` (on the Pi only — never commit)
2. Update `AllowUsers` in `sshd_config` to your Pi username
3. Verify ProtonVPN peer endpoint is current for your account
4. Test the **kill-switch**: stop WireGuard and confirm no traffic leaks on `wlan0`

## DNS stack ports

| Service | Listen address |
|---|---|
| Pi-hole | `0.0.0.0:53` |
| Unbound | `127.0.0.1:5335` |
| DNSCrypt-proxy | `127.0.0.1:5353` |
