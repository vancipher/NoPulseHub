# NoPulse-HUB

**A hardened Raspberry Pi security router — VPN, DNS privacy, firewall, and kill-switch in one box.**

[![Cyber X Project](https://img.shields.io/badge/Cyber%20X-Project%20Page-blue?style=flat-square)](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub)

---

## What is NoPulse-HUB?

NoPulse-HUB is an integrated security platform built on a **Raspberry Pi 3**, turned into a secure router that combines network protection, encrypted communications, and digital identity privacy in one interconnected system.

> يقدّم هذا المشروع بناء منصة أمنية متكاملة اعتمادًا على Raspberry Pi 3، حيث تم تحويله إلى جهاز راوتر آمن يجمع بين حماية الشبكة، وتشفير الاتصالات، وإخفاء الهوية الرقمية ضمن منظومة واحدة مترابطة.

**Author:** Abdullah Yasir · **Team:** [Cyber X](https://cyberxsec.me/) · **Status:** Demo

---

## Why this repo exists

The **full codebase and live configs live on the Raspberry Pi hardware**, not on a development machine. This repository documents the project and preserves the configuration files published on the [Cyber X project page](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub) so others can study, reproduce, and extend the setup.

### What's included here

| Included | Not on this machine |
|---|---|
| Network, firewall, DNS, SSH, VPN configs | Application source code |
| Architecture & security documentation | Pi-hole / Unbound runtime state |
| Deployment paths for Raspberry Pi | Private keys & live credentials |

---

## How it works

```
Laptop ──► eth0 (10.8.0.1) ──► Raspberry Pi ──► wlan0 ──► Internet
                                    │
                                    ├── Pi-hole (ad blocking)
                                    ├── Unbound → DNSCrypt (encrypted DNS)
                                    ├── nftables (firewall, default DROP)
                                    └── WireGuard → ProtonVPN (kill-switch)
```

A laptop connects over Ethernet to the Pi. All traffic is routed through the Pi's security stack before reaching the internet. If the VPN drops, the kill-switch blocks outbound traffic on `wlan0`.

---

## Security layers

| Layer | Technology | Purpose |
|---|---|---|
| **Routing** | IP forwarding, dual NIC | Pi acts as secure gateway |
| **Kernel** | `sysctl` hardening | Anti-spoofing, no ICMP redirects, SYN cookies, stealth ping |
| **Firewall** | nftables | Default DROP; allow only SSH 2222, DNS, DHCP, Pi-hole web UI |
| **DNS** | Pi-hole + Unbound + DNSCrypt | Block ads, resolve locally, encrypt upstream (DoH) |
| **VPN** | WireGuard + ProtonVPN | Full tunnel with kill-switch |
| **SSH** | Port 2222, Ed25519 keys only | No passwords, Fail2Ban, single user |
| **IPv6** | Fully disabled | Prevent VPN/DNS leaks |

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full technical detail.

---

## Repository structure

```
NoPulseHub/
├── configs/
│   ├── netplan-network.yaml   # Dual-interface network layout
│   ├── sysctl.conf            # Kernel hardening
│   ├── nftables.conf          # Firewall rules
│   ├── unbound.conf           # Local DNS resolver
│   ├── sshd_config            # Hardened SSH
│   ├── wireguard-wg0.conf     # VPN (private key placeholder)
│   └── README.md              # Pi install paths
├── docs/
│   ├── ARCHITECTURE.md        # Full project documentation
│   └── english-sections.txt   # Extracted English explanations
└── README.md
```

---

## Quick start (Raspberry Pi)

1. Flash **Raspberry Pi OS** (64-bit recommended) onto your Pi 3.
2. Copy configs from `configs/` to the paths listed in [configs/README.md](configs/README.md).
3. Set your WiFi PSK, WireGuard private key, and SSH username **on the Pi only**.
4. Install services: `pi-hole`, `unbound`, `dnscrypt-proxy`, `wireguard`, `nftables`, `fail2ban`.
5. Apply netplan: `sudo netplan apply`
6. Enable WireGuard: `sudo systemctl enable --now wg-quick@wg0`
7. Load firewall: `sudo nft -f /etc/nftables.conf`

> **Note:** This is a demo configuration. Review all rules and credentials before production use.

---

## Planned enhancements

- ProxyChains (multi-hop proxy chain)
- RAM-only browser cache
- MAC address randomization
- Anti-fingerprinting
- Suricata IDS
- Cowrie honeypot
- Tor integration
- DNS over TLS
- Encrypted config backups

---

## Legal & ethical use

This project is for **education, research, and authorized network hardening** only. Deploy only on networks and devices you own or have permission to configure. VPN endpoints and firewall rules must comply with your jurisdiction and provider terms.

---

## Links

- **Project page:** [cyberxsec.me/Projects/detail.html?slug=NoPulseHub](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub)
- **Cyber X:** [cyberxsec.me](https://cyberxsec.me/)

---

<p align="center">
  <em>Prepared by Abdullah Yasir · Cyber X · Northern Technical University</em>
</p>
