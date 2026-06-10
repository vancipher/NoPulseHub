# NoPulse-HUB (Demo)

**Personal internet protection platform — a Raspberry Pi security router that combines network hardening, encrypted DNS, VPN tunneling, and a kill-switch in one integrated system.**

[![Cyber X Project](https://img.shields.io/badge/Project-Cyber%20X-purple?style=flat-square)](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub)

**Author:** Abdullah Yasir · **Developer:** Van De Cipher · **Team:** [Cyber X](https://cyberxsec.me/)

> Source: [cyberxsec.me/Projects/detail.html?slug=NoPulseHub](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub)

---

## Table of Contents

1. [Introduction](#introduction)
2. [Who Can See Your Traffic?](#who-can-see-your-traffic)
3. [How DNS and Your ISP Expose You](#how-dns-and-your-isp-expose-you)
4. [The Solution: A Private Security Hub](#the-solution-a-private-security-hub)
5. [Demo Status](#demo-status)
6. [Project Architecture & Core Services](#project-architecture--core-services)
7. [Network Configuration](#network-configuration)
8. [Kernel Hardening (sysctl)](#kernel-hardening-sysctl)
9. [Firewall (nftables)](#firewall-nftables)
10. [Secure DNS Stack](#secure-dns-stack)
11. [SSH Hardening](#ssh-hardening)
12. [WireGuard VPN](#wireguard-vpn)
13. [Future Planned Features](#future-planned-features)
14. [Challenges, Lessons & Weaknesses](#challenges-lessons--weaknesses)
15. [User Recommendations](#user-recommendations)
16. [Configuration Files](#configuration-files)
17. [Repository Note](#repository-note)
18. [Legal Notice](#legal-notice)

---

## Introduction

A question that comes up constantly: **How do I protect myself on the internet, preserve my privacy, and avoid being tracked?** And how do I defend against the many types of attacks that can happen every day?

Security tools are numerous and complex. We chose to assemble a meaningful subset of them into a single security system — enough that **your private data does not reach third parties**.

First, we need to understand something important: **who is capable of seeing our traffic and violating our privacy?**

---

## Who Can See Your Traffic?

| Actor | Risk |
|---|---|
| **Ad networks** | Tracking, malware-laden ads, aggressive profiling |
| **Malicious websites** | Exploits, phishing, drive-by downloads |
| **Governments** | Mass surveillance, traffic inspection |
| **Hackers** | MITM attacks, credential theft, network scanning |
| **ISP (Internet Service Provider)** | Full visibility into DNS queries and unencrypted traffic |

Ad networks are everywhere and are often loaded with malware — not just annoying, but dangerous.

---

## How DNS and Your ISP Expose You

Your ISP is the company that provides your internet connection. They can see **which websites you request** and observe your data flows. This is natural — to deliver what you ask for, they must know the site name (the **Domain Name**) you are trying to reach.

That domain is sent to their DNS servers, converted to an IP address, and the connection is made to the remote server. **Sensitive data can be exposed to the ISP during this process.**

The good news: you can **stop relying on their services**, run the same functions on your own hardware, eliminate third-party visibility, hide yourself from your ISP, block malicious sites, and make tracking significantly harder — if not impossible.

---

## The Solution: A Private Security Hub

We assembled a substantial set of protection tools on a **Raspberry Pi 3**, configured to act as a **router or hub**:

```
Laptop ──Ethernet──► Raspberry Pi (security hub) ──WiFi──► Internet
```

- Your computer connects via **Ethernet cable** to avoid wireless exposure on the LAN link
- The Pi sits **between you and the internet**, responsible for protecting your data
- Can optionally be configured as a **wireless hub** to secure all home devices

### Traffic path

```
Ethernet → WLAN → WireGuard (wg0)
```

Unnecessary system services were disabled to reduce attack surface.

---

## Demo Status

> **This release is a Demo — not a final production version.** Some features are still missing and we are still gaining experience. Use it as a learning platform and lab environment.

---

## Project Architecture & Core Services

### 1. IP Forwarding (Core Routing)

Forwards packets from your computer toward the internet. Traffic path:

```
Ethernet → WLAN → WireGuard (wg0)
```

### 2. Kernel Hardening

Protects the device from well-known attacks through strict kernel rules:

- **Disable IPv6 entirely** — prevents leaks outside the VPN tunnel
- **Anti-spoofing** — reverse path filtering blocks forged source addresses
- **Block ICMP redirects** — prevents MITM redirect attacks
- **SYN flood protection** — syncookies defend against connection exhaustion
- **Kernel log restriction** — limits access to sensitive dmesg output

### 3. Firewall (nftables)

Uses **nftables** (modern replacement for iptables) with rules to:

- Close all unused ports
- Allow only authorized connections on specific ports
- **Kill-switch**: cuts all traffic if the VPN drops — preventing data leaks

### 4. DNS Security (Three Tools)

| Tool | Role |
|---|---|
| **Pi-hole** | Blocks ads and malicious domains |
| **Unbound** | Local recursive DNS resolver — no ISP dependency |
| **DNSCrypt-proxy / DoH** | Encrypts upstream DNS queries, bypasses port 53 blocking |

### 5. SSH Hardening

- Port changed from **22 → 2222**
- **Single user** allowed (`AllowUsers cipher`)
- **SSH keys only** — passwords disabled
- **X11 Forwarding** disabled
- **Fail2Ban** blocks brute-force attempts

### 6. WireGuard VPN

Raspberry Pi connected to **ProtonVPN** via WireGuard:

- Hides your real IP address
- Routes **all traffic** through an encrypted tunnel
- ISP sees only encrypted VPN traffic, not destinations

### 7. Planned Future Additions

- ProxyChains (3-proxy chain)
- RAM-only browser cache
- MAC address randomization
- Anti-fingerprinting
- Suricata IDS
- Cowrie honeypot

---

## Network Configuration

Config file: [`configs/netplan-network.yaml`](configs/netplan-network.yaml)  
Install path on Pi: `/etc/netplan/01-nopulse.yaml`

### Explanation

This configuration sets up the Raspberry Pi with two network interfaces:

| Interface | Role | Address |
|---|---|---|
| `eth0` (Ethernet) | LAN — laptop connection | `10.8.0.1/24` |
| `wlan0` (WiFi) | WAN — upstream router | `192.168.0.50/24` |

**Key points:**

- No DHCP on `eth0` (DHCP for connected devices handled separately)
- Static IP addressing on both interfaces
- Default gateway via main router (`192.168.0.1`)
- Google DNS (`8.8.8.8`) as fallback nameserver
- Hidden WiFi network for upstream connectivity

**Network path:**

```
Laptop → eth0 (10.8.0.1) → Pi processing → wlan0 → Internet
```

```yaml
# See configs/netplan-network.yaml for full file
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [10.8.0.1/24]
  wifis:
    wlan0:
      addresses: [192.168.0.50/24]
      routes: [{ to: default, via: 192.168.0.1 }]
```

---

## Kernel Hardening (sysctl)

Config file: [`configs/sysctl.conf`](configs/sysctl.conf)  
Install path on Pi: append to `/etc/sysctl.conf`, then `sudo sysctl -p`

These settings are applied at boot. The goal is to restrict network and kernel behavior to prevent address leaks, MITM techniques, protocol abuse, and memory/process exposure.

### Settings explained

| Setting | Value | Why |
|---|---|---|
| `net.ipv4.ip_forward` | `1` | Required for routing between interfaces |
| `net.ipv6.conf.*.disable_ipv6` | `1` | When VPN is IPv4-only, IPv6 can leak outside the tunnel exposing your real address |
| `net.ipv4.conf.all.rp_filter` | `1` | Reverse path filtering — drops packets with impossible return paths (anti-spoofing) |
| `net.ipv4.conf.all.accept_redirects` | `0` | ICMP redirects let attackers redirect your gateway (MITM) — must be blocked |
| `net.ipv4.icmp_echo_ignore_all` | `1` | No ping replies — harder to discover device via network scan (stealth) |
| `net.ipv4.tcp_syncookies` | `1` | Protects against SYN flood attacks that fill connection queues |
| `net.ipv4.conf.all.log_martians` | `1` | Logs packets with impossible source addresses (spoofing attempts) |
| `net.ipv4.conf.all.accept_source_route` | `0` | Blocks source routing that can force traffic through attacker routers |
| `net.ipv4.tcp_timestamps` | `0` | Disables TCP timestamp fingerprinting used to identify OS type |
| `kernel.dmesg_restrict` | `1` | Prevents unprivileged users reading kernel logs with sensitive info |
| `kernel.kptr_restrict` | `2` | Hides kernel pointer addresses |
| `kernel.yama.ptrace_scope` | `1` | Restricts process tracing |

---

## Firewall (nftables)

Config file: [`configs/nftables.conf`](configs/nftables.conf)  
Install path on Pi: `/etc/nftables.conf`

nftables is faster and more flexible than iptables, handling IPv4 and IPv6 in one table.

### INPUT chain — incoming to Pi

- **Default policy: DROP**
- Allow established/related connections
- Allow loopback
- Allow ICMP ping from LAN (`eth0`) only
- Allow SSH port **2222** from `eth0` and `wlan0`
- Allow DNS queries from LAN (UDP/TCP port 53)
- Allow HTTP/HTTPS for Pi-hole admin interface
- Allow DHCP and NTP
- Log and drop everything else (rate-limited)

### FORWARD chain — traffic through Pi

- **Default policy: DROP**
- Allow established/related connections
- Allow `eth0 → wg0` (LAN to VPN)
- Allow `eth0 → wlan0` (LAN to internet fallback)
- Contains **kill-switch logic**
- Log and drop all other forwarding

### OUTPUT chain — outgoing from Pi

- Default policy: **ACCEPT**
- Explicitly allows DNS over HTTPS (port 443)

### Additional rules

- **IPv6 chains**: all IPv6 traffic blocked (input, forward, output)
- **WireGuard tables**: managed by `wg-quick` for WireGuard packet handling

---

## Secure DNS Stack

Three-layer DNS protection architecture:

```
Client → Pi-hole (53) → Unbound (5335) → DNSCrypt-proxy (5353) → DoH upstream
```

### Layer 1 — Pi-hole

- Receives DNS queries from users on port **53**
- Checks against blocklists (ads + malicious domains)
- Returns block response for banned names
- Passes allowed queries to Unbound
- Web admin interface on ports **80/443**

### Layer 2 — Unbound

Config file: [`configs/unbound.conf`](configs/unbound.conf)

- Local recursive DNS resolver
- Listens on `127.0.0.1:5335` (not port 53)
- **QNAME minimisation** — sends only minimum required query info per resolver hop, protecting browsing privacy
- Caching speeds up repeat queries and reduces external network dependency
- Forwards all queries to DNSCrypt-proxy

### Layer 3 — DNSCrypt-proxy

- Listens on `127.0.0.1:5353`
- Encrypts queries using **DNS over HTTPS (DoH)**
- Connects to external encrypted DNS servers
- Bypasses ISP blocking of port 53
- Protects query content from inspection

---

## SSH Hardening

Config file: [`configs/sshd_config`](configs/sshd_config)  
Install path on Pi: `/etc/ssh/sshd_config.d/nopulse.conf`

| Setting | Value | Purpose |
|---|---|---|
| Port | `2222` | Avoids automated port-22 bot scans |
| AllowUsers | `cipher` | Only one user can login |
| PasswordAuthentication | `no` | Keys only — no brute-force passwords |
| PermitRootLogin | `no` | No direct root SSH access |
| X11Forwarding | `no` | Prevents graphical data leaks and MITM via X11 |
| PubkeyAcceptedKeyTypes | `ssh-ed25519` | Modern, fast, secure cryptography |

**Fail2Ban integration:**

- Monitors `/var/log/auth.log`
- Bans IPs after **3 failed attempts** within 10 minutes
- Ban duration: **1 hour**

This configuration makes SSH attacks practically impossible over the internet.

---

## WireGuard VPN

Config file: [`configs/wireguard-wg0.conf`](configs/wireguard-wg0.conf)  
Install path on Pi: `/etc/wireguard/wg0.conf`

WireGuard was chosen because it is:

- Lighter and faster than OpenVPN
- Small codebase (~4000 lines) — fewer vulnerabilities
- Modern crypto: ChaCha20, Poly1305, Curve25519
- Easier to configure and manage

### Configuration components

**Interface:**

| Field | Value |
|---|---|
| PrivateKey | Pi's private key (set locally — never commit) |
| Address | `10.2.0.2/32` |
| PostUp/PreDown | Kill-switch commands |

**Peer (ProtonVPN — RO-FREE#5):**

| Field | Value |
|---|---|
| PublicKey | `jDAyArm/Gg+ONoEfAawsibdNRTTGZcfAvgan+bGD0G8=` |
| AllowedIPs | `0.0.0.0/0, ::/0` (full tunnel) |
| Endpoint | `138.199.53.237:51820` |
| PersistentKeepalive | `25` |

### Kill-switch

```ini
PostUp   = iptables -I FORWARD -o wlan0 -j REJECT
PreDown  = iptables -D FORWARD -o wlan0 -j REJECT
```

When `wg0` is up, traffic routes through VPN. When VPN drops, `wlan0` forwarding is **blocked** — no cleartext leak.

**Full tunnel:** `AllowedIPs = 0.0.0.0/0, ::/0` means **all** IPv4 and IPv6 traffic goes through VPN. No split tunneling exceptions.

**Result:** All LAN traffic exits to the internet via encrypted WireGuard tunnel to ProtonVPN — real IP hidden from ISP, data protected from inspection.

---

## Future Planned Features

1. **ProxyChains** — chain of three proxies for additional anonymity
2. **RAM-only browser cache** — cleared on shutdown, no disk persistence
3. **MAC address randomization** — harder to track on local networks
4. **Anti-fingerprinting** — reduce browser/system uniqueness
5. **Suricata IDS** — real-time attack pattern detection
6. **Cowrie honeypot** — attract and study attackers
7. **Tor integration** — selective Tor routing for specific apps
8. **DNS over TLS** — alternative encrypted DNS to DoH
9. **Traffic analysis** — bandwidth monitoring and connection logging
10. **Encrypted backups** — secure config and key backup with scheduling

---

## Challenges, Lessons & Weaknesses

### Challenges faced

1. Complexity of nftables rule management
2. Service compatibility issues between components
3. Difficult routing debugging when errors occur
4. Balancing security vs. performance on limited hardware
5. Memory management on resource-constrained Raspberry Pi

### Lessons learned

- Security is a **continuous process**, not a final product
- Documentation of every step and setting is critical
- Comprehensive testing before deployment is essential
- Simplicity in design has real value

### Current weaknesses

- Dependency on external services (ProtonVPN)
- Complexity may be a barrier for average users
- Requires regular maintenance and security updates
- Resource consumption on Raspberry Pi

### Future vision

- Simple web UI for system management
- Pre-built configs for different hardware
- Detailed educational tutorials
- User community for knowledge sharing

> **Remember:** Absolute security does not exist — but we can make attacks significantly harder and more expensive for adversaries.

---

## User Recommendations

1. Keep backups of all keys and configuration files
2. Test the system fully before relying on it
3. Follow security updates for all tools used
4. Understand what you are doing before applying settings
5. Start with a demo environment — do not use for sensitive data immediately

---

## Configuration Files

| File | Pi install path |
|---|---|
| [`configs/netplan-network.yaml`](configs/netplan-network.yaml) | `/etc/netplan/01-nopulse.yaml` |
| [`configs/sysctl.conf`](configs/sysctl.conf) | `/etc/sysctl.conf` |
| [`configs/nftables.conf`](configs/nftables.conf) | `/etc/nftables.conf` |
| [`configs/unbound.conf`](configs/unbound.conf) | `/etc/unbound/unbound.conf.d/nopulse.conf` |
| [`configs/sshd_config`](configs/sshd_config) | `/etc/ssh/sshd_config.d/nopulse.conf` |
| [`configs/wireguard-wg0.conf`](configs/wireguard-wg0.conf) | `/etc/wireguard/wg0.conf` |

See [`configs/README.md`](configs/README.md) for install instructions.

### Quick deploy checklist

```bash
# On Raspberry Pi 3
sudo apt install pi-hole unbound dnscrypt-proxy wireguard nftables fail2ban

# Copy configs to paths above
sudo netplan apply
sudo sysctl -p
sudo systemctl enable --now wg-quick@wg0 nftables fail2ban

# Test kill-switch: stop WireGuard, confirm no cleartext traffic leaks
sudo systemctl stop wg-quick@wg0
```

---

## Repository Note

The **full runtime environment and live credentials live on the Raspberry Pi hardware**, not on a development machine. This repository preserves the complete project documentation and configuration files as published on the [Cyber X project page](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub).

---

## Legal Notice

```
⚠️  EDUCATIONAL / AUTHORIZED USE ONLY
```

Deploy only on networks and devices you own or have written permission to configure. VPN usage and network modifications must comply with your jurisdiction and provider terms. You are solely responsible for how you use this system.

---

<p align="center">
  <em>Developed with patience, passion, and persistence.</em><br>
  <strong>Abdullah Yasir · Van De Cipher · Cyber X</strong>
</p>
