# Architecture Reference

The complete English project documentation — including threat model, all seven security layers, every sysctl setting, firewall chains, DNS stack, SSH hardening, WireGuard kill-switch, challenges, and deployment checklist — is in the main **[README.md](../README.md)**.

This file exists as a navigation anchor. All content from the [Cyber X project page](https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub) has been translated to English and included there in full.

## Quick reference

```
Laptop
  └── eth0 (10.8.0.1) ──► Raspberry Pi 3
                              ├── Pi-hole (DNS filter)
                              ├── Unbound (local resolver)
                              ├── DNSCrypt-proxy (DoH upstream)
                              ├── nftables (firewall + kill-switch)
                              ├── WireGuard → ProtonVPN
                              └── SSH :2222 (key-only)
                                    └── wlan0 (192.168.0.50) ──► Internet
```

Configuration files: [`../configs/`](../configs/)
