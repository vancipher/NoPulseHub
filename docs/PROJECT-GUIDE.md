# NoPulse-HUB — Complete project guide

> **Demo release** · Cyber X · [cyberxsec.me](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub)  
> **Author:** Abdullah Yasir (Van De Cipher / [@vancipher](https://github.com/vancipher))

This document is the **written version** of the original NoPulse-HUB presentation — all technical explanations in one place, without slide images. Config files live in [`../configs/`](../configs/).

---

## 1. Why this project exists

Common questions this project tries to answer:

- How do I protect myself on the internet?
- How do I keep my privacy and avoid being tracked?
- How do I reduce exposure to everyday network attacks?

Security tools are powerful but fragmented. NoPulse-HUB **combines a practical subset** into one box so private traffic does not depend on third parties you do not control.

### Who can see your traffic today?

| Actor | What they can do |
|---|---|
| **Ad networks** | Track you across sites; ads often carry malware |
| **Malicious websites** | Exploits, phishing, drive-by downloads |
| **Governments** | Mass surveillance, traffic inspection |
| **Hackers** | MITM, credential theft, scanning |
| **ISP** | See DNS queries and unencrypted traffic metadata |

Your ISP must resolve domain names to IP addresses — that process can expose **what you browse** unless you stop using their DNS and route traffic differently.

### The idea

Run the same functions **on your own hardware** (Raspberry Pi 3):

- Stop third parties from watching DNS and routing decisions
- Block ads and known-bad domains locally
- Encrypt outbound traffic through a VPN tunnel
- Cut all traffic if the VPN fails (**kill-switch**)

```
Laptop ──Ethernet (eth0)──► Raspberry Pi 3 ──WiFi + antenna (wlan0)──► Router ──► Internet
                                    │
                                    └── WireGuard (wg0) ──► ProtonVPN
```

**Why Ethernet to the laptop?** Avoids an extra wireless hop on the trusted side. The Pi can later be extended as a wireless hub for a whole home.

**Demo status:** This is a **lab / demo build**, not a finished consumer product. Some features are still planned; configs were tested on multiple machines and on the Pi with an **external WiFi antenna** before deployment.

---

## 2. Core services (overview)

### 2.1 IP forwarding — the Pi as a router

Traffic path:

```
Ethernet → WLAN → WireGuard (wg0)
```

- `net.ipv4.ip_forward = 1` turns Linux into a router.
- Packets arriving on `eth0` are evaluated by **nftables** and the routing table, then forwarded toward `wlan0` and into the VPN tunnel.
- Unnecessary system services were disabled to shrink attack surface.

Network layout uses **netplan** with **systemd-networkd** for stable interface management.

### 2.2 Kernel hardening (`sysctl`)

Settings in [`configs/sysctl.conf`](../configs/sysctl.conf) apply at boot.

| Setting | Purpose |
|---|---|
| Disable IPv6 on all interfaces | When VPN is IPv4-only, IPv6 can **leak outside the tunnel** and reveal your real address |
| `rp_filter = 1` | Reverse-path filtering — drops spoofed source addresses |
| `accept_redirects = 0` | Blocks ICMP redirect MITM |
| `send_redirects = 0` | Pi will not redirect other hosts |
| `icmp_echo_ignore_all = 1` | No ping replies — harder to spot on scans |
| `tcp_syncookies = 1` | SYN flood mitigation |
| `log_martians = 1` | Log impossible source IPs (forensics / IDS prep) |
| `accept_source_route = 0` | Blocks source-routed packets through attacker paths |
| `tcp_timestamps = 0` | Reduces TCP fingerprinting |
| `kernel.dmesg_restrict` / `kptr_restrict` | Limits kernel info leaks to unprivileged users |

Full file with comments: see README [Kernel Hardening](../README.md#kernel-hardening-sysctl) section.

### 2.3 Firewall — nftables

Modern replacement for iptables — one framework for IPv4/IPv6 rules.

**INPUT chain (to the Pi itself)**

- Default: **DROP**
- Allow: established sessions, loopback, ICMP from LAN only, SSH **2222**, DNS from LAN, Pi-hole web UI (80/443), DHCP, NTP
- Rate-limited logging on drops

**FORWARD chain (through the Pi)**

- Default: **DROP**
- Allow: `eth0 → wg0` (LAN into VPN)
- Allow: `eth0 → wlan0` only when policy permits (fallback path — kill-switch handles VPN-down case)
- Contains **kill-switch logic** with WireGuard PostUp/PreDown

**OUTPUT chain**

- Default: ACCEPT for Pi services
- Explicit allow for DNS-over-HTTPS (443) to upstream resolvers

**IPv6:** All input/forward/output **blocked** — consistent with IPv6 disabled in sysctl.

Config: [`configs/nftables.conf`](../configs/nftables.conf)

### 2.4 DNS security — three layers

```
Client → Pi-hole (:53) → Unbound (:5335) → DNSCrypt-proxy (:5353) → DoH upstream
```

| Layer | Role |
|---|---|
| **Pi-hole** | Blocklists for ads + malware; admin UI on 80/443 |
| **Unbound** | Local recursive resolver; **qname-minimisation**; cache on the Pi |
| **DNSCrypt-proxy** | **DNS over HTTPS** to external resolvers |

**Why DoH was required (real deployment lesson):** On our network the **ISP blocked plain DNS (port 53)**. Pi-hole and Unbound alone could not reach the internet for resolution. DNSCrypt over **HTTPS (port 443)** bypasses that restriction — traffic looks like normal web TLS.

Unbound config: [`configs/unbound.conf`](../configs/unbound.conf)

### 2.5 SSH hardening

| Setting | Value | Why |
|---|---|---|
| Port | **2222** | Avoids automated port-22 bots |
| `AllowUsers` | `cipher` | Single allowed account |
| Authentication | **Ed25519 keys only** | No password logins |
| `PermitRootLogin` | `no` | No direct root |
| `X11Forwarding` | `no` | Prevents X11 data leaks |
| **Fail2Ban** | 3 fails / 10 min → 1 h ban | Blocks brute force |

Config: [`configs/sshd_config`](../configs/sshd_config)

### 2.6 WireGuard VPN

Connected to **ProtonVPN** (demo peer: RO-FREE#5).

**Why WireGuard?**

- Smaller codebase than OpenVPN (~4k lines)
- Fast, modern crypto (ChaCha20, Poly1305, Curve25519)
- Simple static config

**Interface**

- Pi address: `10.2.0.2/32`
- `PostUp` / `PreDown` iptables rules = **kill-switch**

```ini
PostUp   = iptables -I FORWARD -o wlan0 -j REJECT
PreDown  = iptables -D FORWARD -o wlan0 -j REJECT
```

When `wg0` is up, forwarding uses the tunnel. When VPN drops, **wlan0 forward is rejected** — no cleartext leak.

**Full tunnel:** `AllowedIPs = 0.0.0.0/0, ::/0` — no split tunneling.

**Runtime notes from deployment**

- `listening port` — local UDP port for WireGuard session (often dynamic)
- `fwmark` (e.g. `0xca6c`) — used with nftables to mark WireGuard traffic for correct NAT/masquerade handling

Config template: [`configs/wireguard-wg0.conf`](../configs/wireguard-wg0.conf) — **replace `PrivateKey` on the Pi only; never commit real keys.**

---

## 3. Network configuration

File: [`configs/netplan-network.yaml`](../configs/netplan-network.yaml) → `/etc/netplan/01-nopulse.yaml`

| Interface | Role | Address |
|---|---|---|
| `eth0` | LAN — laptop | `10.8.0.1/24`, no DHCP server on eth0 itself |
| `wlan0` | WAN — upstream WiFi | `192.168.0.50/24`, gateway `192.168.0.1` |

**Deployment details**

- **Static IPs** on both LAN and WAN sides
- **DHCP reservation** on the home router for the Pi WLAN MAC — stable `192.168.0.50`
- Fallback nameserver `8.8.8.8` in netplan when local DNS stack is down
- Hidden upstream WiFi SSID in lab config (see yaml — use your own AP credentials)

**Traffic flow**

1. Laptop plugs into `eth0`
2. DNS queries hit Pi-hole on the Pi
3. Resolved traffic is forwarded to `wlan0`
4. WireGuard encrypts everything to ProtonVPN endpoint

---

## 4. Planned future features

From the original roadmap (not all implemented in demo):

1. **ProxyChains** — chain of three proxies for extra anonymity
2. **RAM-only browser cache** — nothing sensitive on disk
3. **MAC address randomization** on WAN
4. **Anti-fingerprinting** — browser / system tweaks
5. **Suricata IDS** — live attack detection
6. **Cowrie honeypot** — study attacker behaviour
7. **Tor integration** — selective routing for specific apps
8. **DNS-over-TLS** — alternative to DoH
9. **Traffic analytics** — bandwidth / connection logging
10. **Encrypted config backups**

---

## 5. Challenges, lessons, and weaknesses

### Challenges faced

1. nftables rule ordering and debugging
2. Service startup order (Pi-hole ↔ Unbound ↔ DNSCrypt)
3. Routing mistakes hard to trace without logging
4. Balancing security vs Pi 3 CPU/RAM limits
5. ISP DNS blocking — required DoH workaround

### Lessons learned

- Security is a **process**, not a one-time install
- Document every sysctl and firewall line — future-you will need it
- Test kill-switch by **stopping WireGuard** and confirming zero leak
- Test on a **spare machine** before trusting the Pi on real traffic
- Simpler topologies fail less often than over-engineered ones

### Current weaknesses

- Depends on **ProtonVPN** (or whichever peer you configure)
- Not plug-and-play for non-technical users
- Needs updates (Pi-hole lists, OS patches, VPN keys)
- Raspberry Pi 3 is slow under heavy throughput

### Recommendations before you rely on it

1. Backup all keys and configs offline
2. Run leak tests (DNS + IP) with VPN up and down
3. Keep a **recovery SD card image**
4. Start in a lab — not for sensitive data on day one
5. Understand each config file before copying to production

---

## 6. Quick deploy reference

```bash
# On Raspberry Pi 3
git clone https://github.com/vancipher/NoPulseHub.git
cd NoPulseHub
sudo bash scripts/install.sh

sudo apt install pi-hole unbound dnscrypt-proxy wireguard fail2ban
# Place your real wg0.conf with private key on the Pi
sudo systemctl enable --now wg-quick@wg0

# Kill-switch test
sudo systemctl stop wg-quick@wg0
# Verify laptop loses internet rather than leaking cleartext
```

| Config file | Install path on Pi |
|---|---|
| `netplan-network.yaml` | `/etc/netplan/01-nopulse.yaml` |
| `sysctl.conf` | append to `/etc/sysctl.conf` → `sudo sysctl -p` |
| `nftables.conf` | `/etc/nftables.conf` |
| `unbound.conf` | `/etc/unbound/unbound.conf.d/nopulse.conf` |
| `sshd_config` | `/etc/ssh/sshd_config.d/nopulse.conf` |
| `wireguard-wg0.conf` | `/etc/wireguard/wg0.conf` |

---

## 7. Legal

Educational / authorized use only. Configure only networks and hardware you own or have written permission to modify. VPN use must follow provider terms and local law.

---

<p align="center"><em>Developed with patience, passion, and persistence.</em><br><strong>Cyber X · Van De Cipher</strong></p>
