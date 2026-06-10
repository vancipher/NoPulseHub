# Configuration Files

These files were recovered from the [NoPulseHub project page](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub). The live deployment runs on a **Raspberry Pi 3** — this repo holds the documented configs, not the full runtime environment.

## Raspberry Pi install paths

| File in repo | Target path on Pi |
|---|---|
| `netplan-network.yaml` | `/etc/netplan/01-nopulse.yaml` |
| `sysctl.conf` | Append to `/etc/sysctl.conf`, then `sudo sysctl -p` |
| `nftables.conf` | `/etc/nftables.conf` — enable with `sudo systemctl enable --now nftables` |
| `unbound.conf` | `/etc/unbound/unbound.conf.d/nopulse.conf` |
| `sshd_config` | Merge into `/etc/ssh/sshd_config.d/nopulse.conf` |
| `wireguard-wg0.conf` | `/etc/wireguard/wg0.conf` — **add your private key locally, never commit it** |

## Before applying

1. Replace `YOUR_WIFI_PSK` in `netplan-network.yaml` with your access-point password.
2. Replace `[PRIVATE_KEY_HERE]` in `wireguard-wg0.conf` with your WireGuard private key (on the Pi only).
3. Update `AllowUsers` in `sshd_config` to your Pi username.
4. Review ProtonVPN peer/endpoint values — rotate if this is a production deployment.

## Services stack (on Pi)

- **Pi-hole** — network-wide ad/tracker blocking
- **Unbound** — local recursive DNS resolver (port 5335)
- **DNSCrypt-proxy** — encrypted upstream DNS (DoH, port 5353)
- **WireGuard** — VPN tunnel with kill-switch
- **nftables** — firewall (default DROP policy)
- **Fail2Ban** — SSH brute-force protection
- **SSH** — key-only auth on port 2222
