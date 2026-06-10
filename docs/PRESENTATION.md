# NoPulse-HUB — Full project documentation (slides)

Original presentation slides and PDF exported from the Cyber X project. Use alongside [`README.md`](../README.md) and [`ARCHITECTURE.md`](ARCHITECTURE.md).

**PDF (all slides):** [`NoPulseHUB.pdf`](NoPulseHUB.pdf)

---

## Slide index

| Slides | Topic |
|---|---|
| [IMG_2083](slides/IMG_2083.JPEG) | Introduction — privacy problem, ISP/DNS exposure, Raspberry Pi hub concept |
| [IMG_2084](slides/IMG_2084.JPEG) – [IMG_2089](slides/IMG_2089.JPEG) | Core services — IP forwarding, kernel hardening, nftables, DNS stack, SSH, WireGuard |
| [IMG_2090](slides/IMG_2090.JPEG) – [IMG_2095](slides/IMG_2095.JPEG) | Kernel hardening (`sysctl`) — martians, source routing, TCP stack |
| [IMG_2096](slides/IMG_2096.JPEG) – [IMG_2102](slides/IMG_2102.JPEG) | `nftables` firewall — INPUT / FORWARD / OUTPUT chains, IPv6 block |
| [IMG_2103](slides/IMG_2103.JPEG) – [IMG_2107](slides/IMG_2107.JPEG) | Secure DNS — Pi-hole → Unbound → DNSCrypt (DoH), qname-minimisation |
| [IMG_2109](slides/IMG_2109.JPEG) – [IMG_2112](slides/IMG_2112.JPEG) | SSH hardening — port 2222, Ed25519 keys, Fail2Ban |
| [IMG_2113](slides/IMG_2113.JPEG) – [IMG_2115](slides/IMG_2115.JPEG) | WireGuard VPN, kill-switch, challenges, lessons, future work |

> **Note:** `IMG_2108` was not in the source export.

---

## Network topology (from slides)

```
Laptop ──Ethernet (eth0)──► Raspberry Pi 3 ──WiFi + antenna (wlan0)──► Home router ──► Internet
                              │
                              └── WireGuard (wg0) ──► ProtonVPN
```

| Interface | Role | Address |
|---|---|---|
| `eth0` | LAN — protected client link | `10.8.0.1/24` |
| `wlan0` | WAN — upstream via home router | `192.168.0.50/24` |
| `wg0` | VPN tunnel | `10.2.0.2/32` |

Config files in this repo: [`configs/`](../configs/)

---

## Security layers (summary)

1. **Routing** — IP forwarding; path `Ethernet → WLAN → WireGuard`
2. **Kernel** — IPv6 off, anti-spoofing, no ICMP redirects, SYN cookies, stealth ping
3. **Firewall** — nftables default-drop; kill-switch if VPN drops
4. **DNS** — Pi-hole (blocklists) + Unbound (local resolver) + DNSCrypt (DoH upstream)
5. **SSH** — Port 2222, key-only, single user, Fail2Ban
6. **VPN** — WireGuard full tunnel to ProtonVPN

---

## Gallery

<details>
<summary>All slides (32 images)</summary>

![Intro](slides/IMG_2083.JPEG)

![Slide 2084](slides/IMG_2084.JPEG)
![Slide 2085](slides/IMG_2085.JPEG)
![Slide 2086](slides/IMG_2086.JPEG)
![Slide 2087](slides/IMG_2087.JPEG)
![Slide 2088](slides/IMG_2088.JPEG)
![Slide 2089](slides/IMG_2089.JPEG)
![Slide 2090](slides/IMG_2090.JPEG)
![Slide 2091](slides/IMG_2091.JPEG)
![Slide 2092](slides/IMG_2092.JPEG)
![Slide 2093](slides/IMG_2093.JPEG)
![Slide 2094](slides/IMG_2094.JPEG)
![Slide 2095](slides/IMG_2095.JPEG)
![Slide 2096](slides/IMG_2096.JPEG)
![Slide 2097](slides/IMG_2097.JPEG)
![Slide 2098](slides/IMG_2098.JPEG)
![Slide 2099](slides/IMG_2099.JPEG)
![Slide 2100](slides/IMG_2100.JPEG)
![Slide 2101](slides/IMG_2101.JPEG)
![Slide 2102](slides/IMG_2102.JPEG)
![Slide 2103](slides/IMG_2103.JPEG)
![Slide 2104](slides/IMG_2104.JPEG)
![Slide 2105](slides/IMG_2105.JPEG)
![Slide 2106](slides/IMG_2106.JPEG)
![Slide 2107](slides/IMG_2107.JPEG)
![Slide 2109](slides/IMG_2109.JPEG)
![Slide 2110](slides/IMG_2110.JPEG)
![Slide 2111](slides/IMG_2111.JPEG)
![Slide 2112](slides/IMG_2112.JPEG)
![Slide 2113](slides/IMG_2113.JPEG)
![Slide 2114](slides/IMG_2114.JPEG)
![Slide 2115](slides/IMG_2115.JPEG)

</details>

---

<p align="center"><strong>Cyber X</strong> · <a href="https://cyberxsec.me/Projects/detail.html?slug=NoPulseHub">Project page</a></p>
