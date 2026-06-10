# NoPulse-HUB — Architecture & Security Documentation

> Source: [Cyber X Project — NoPulseHub](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub)  
> Recovered configs live in `../configs/`. Full application code resides on the Raspberry Pi hardware.

---

## Overview

NoPulse-HUB transforms a Raspberry Pi 3 into a **secure network hub** — not just a router, but a layered security appliance. A connected laptop routes all traffic through the Pi, which applies firewall rules, encrypted DNS, VPN tunneling, and kernel hardening before anything reaches the internet.

The demo was built to show how a single low-cost device can provide enterprise-style network security for personal or lab use.

---

## Network topology

### Interfaces

| Interface | Role | Address |
|---|---|---|
| `eth0` | LAN — laptop connection | `10.8.0.1/24` |
| `wlan0` | WAN — upstream router | `192.168.0.50/24`, gateway `192.168.0.1` |
| `wg0` | VPN tunnel (WireGuard) | `10.2.0.2/32` |

### Traffic path

```
Laptop → eth0 (10.8.0.1) → Pi processing → wlan0 / wg0 → Internet
```

- No DHCP on `eth0` by default (DHCP can be added for connected devices).
- Static addressing on both interfaces.
- Hidden WiFi network for upstream connectivity.
- Google DNS (`8.8.8.8`) as fallback nameserver on `wlan0`.

Config: [`configs/netplan-network.yaml`](../configs/netplan-network.yaml)

---

## Layer 1 — Kernel hardening (`sysctl`)

Settings in [`configs/sysctl.conf`](../configs/sysctl.conf) harden the Linux kernel:

| Setting | Purpose |
|---|---|
| `net.ipv4.ip_forward = 1` | Enable routing between interfaces |
| `net.ipv6.conf.*.disable_ipv6 = 1` | Block IPv6 leaks when VPN is IPv4-only |
| `net.ipv4.conf.all.rp_filter = 1` | Anti-spoofing (reverse path filtering) |
| `net.ipv4.conf.all.accept_redirects = 0` | Block ICMP redirect MITM |
| `net.ipv4.icmp_echo_ignore_all = 1` | Stealth mode — no ping replies |
| `net.ipv4.tcp_syncookies = 1` | SYN flood protection |
| `net.ipv4.tcp_timestamps = 0` | Reduce TCP fingerprinting |
| `kernel.dmesg_restrict = 1` | Restrict kernel log access |

Apply: `sudo sysctl -p`

---

## Layer 2 — Firewall (`nftables`)

[`configs/nftables.conf`](../configs/nftables.conf) uses **default DROP** on INPUT and FORWARD chains.

### INPUT chain (incoming to Pi)

- Allow established/related connections
- Allow loopback
- Allow ICMP ping from LAN (`eth0`) only
- Allow SSH on port **2222** from `eth0` and `wlan0`
- Allow DNS (UDP/TCP 53) from LAN
- Allow HTTP/HTTPS for Pi-hole admin interface
- Allow DHCP and NTP
- Log and drop everything else (rate-limited)

### FORWARD chain (traffic through Pi)

- Allow established/related
- Allow `eth0 → wg0` (LAN to VPN)
- Allow `eth0 → wlan0` (LAN to internet fallback)
- Log and drop all other forwarding

### OUTPUT chain

- Default ACCEPT for Pi outbound
- Explicit allow for DNS over HTTPS (port 443)

### Kill-switch

WireGuard `PostUp`/`PreDown` hooks reject forwarded traffic on `wlan0` when the VPN interface is down, preventing cleartext leaks.

---

## Layer 3 — DNS privacy stack

Three-tier DNS architecture:

```
Client → Pi-hole (53) → Unbound (5335) → DNSCrypt-proxy (5353) → DoH upstream
```

### Pi-hole
- Network-wide ad and tracker blocking
- Web dashboard on ports 80/443

### Unbound
- Local recursive resolver on `127.0.0.1:5335`
- QNAME minimisation for privacy
- Forwards all queries to DNSCrypt-proxy
- Refuses queries from `10.8.0.0/24` directly (forces Pi-hole path)

Config: [`configs/unbound.conf`](../configs/unbound.conf)

### DNSCrypt-proxy
- Listens on `127.0.0.1:5353`
- DNS over HTTPS (DoH) to upstream resolvers
- Prevents ISP DNS snooping

---

## Layer 4 — VPN (WireGuard + ProtonVPN)

[`configs/wireguard-wg0.conf`](../configs/wireguard-wg0.conf)

| Parameter | Value |
|---|---|
| Interface address | `10.2.0.2/32` |
| AllowedIPs | `0.0.0.0/0, ::/0` (full tunnel) |
| Endpoint | ProtonVPN server (RO-FREE#5) |
| Keepalive | 25 seconds |

**Kill-switch hooks:**
```ini
PostUp   = iptables -I FORWARD -o wlan0 -j REJECT
PreDown  = iptables -D FORWARD -o wlan0 -j REJECT
```

When `wg0` is up, traffic routes through the VPN. When it drops, `wlan0` forwarding is blocked.

> **Private key is stored on the Pi only.** The repo uses `[PRIVATE_KEY_HERE]` as a placeholder.

---

## Layer 5 — SSH hardening

[`configs/sshd_config`](../configs/sshd_config)

| Setting | Value | Why |
|---|---|---|
| Port | 2222 | Avoid automated port-22 scans |
| AllowUsers | `cipher` | Single allowed user |
| PasswordAuthentication | no | Keys only |
| PermitRootLogin | no | No direct root SSH |
| PubkeyAcceptedKeyTypes | ssh-ed25519 | Modern cryptography |
| MaxAuthTries | 3 | Limit brute-force window |

**Fail2Ban** monitors `/var/log/auth.log` — bans after 3 failures in 10 minutes for 1 hour.

---

## Future roadmap

1. **ProxyChains** — three-proxy chain for additional anonymity
2. **RAM-only browser cache** — no disk persistence
3. **MAC randomization** — periodic interface MAC rotation
4. **Anti-fingerprinting** — reduce browser/system uniqueness
5. **Suricata IDS** — real-time attack detection
6. **Cowrie honeypot** — attract and study attackers
7. **Tor integration** — selective Tor routing
8. **DNS over TLS** — alternative to DoH
9. **Traffic analytics** — bandwidth and connection monitoring
10. **Encrypted backups** — secure config/key backup

---

## Deployment checklist

- [ ] Flash Raspberry Pi OS on Pi 3
- [ ] Copy configs per [configs/README.md](../configs/README.md)
- [ ] Set WiFi PSK and WireGuard private key on device
- [ ] Install Pi-hole, Unbound, DNSCrypt-proxy, WireGuard, nftables, Fail2Ban
- [ ] `sudo netplan apply`
- [ ] `sudo sysctl -p`
- [ ] `sudo systemctl enable --now wg-quick@wg0 nftables fail2ban`
- [ ] Test kill-switch: stop WireGuard, confirm no cleartext leak
- [ ] Test DNS: confirm Pi-hole → Unbound → DNSCrypt chain

---

## Credits

**NoPulse-HUB (Demo)** — Abdullah Yasir · [Cyber X](https://cyberxsec.me/)  
Northern Technical University · Cybersecurity Engineering
