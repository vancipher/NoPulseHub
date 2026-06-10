# Architecture reference

Visual overview of NoPulse-HUB. For full explanations (threat model, each service, DNS DoH workaround, kill-switch, deployment), read **[PROJECT-GUIDE.md](PROJECT-GUIDE.md)**.

## Topology

```
                    ┌─────────────────────────────────────┐
                    │         Raspberry Pi 3              │
  Laptop ──eth0────►│  Pi-hole → Unbound → DNSCrypt(DoH)  │
  10.8.0.x          │  nftables (kill-switch)             │
                    │  WireGuard wg0 → ProtonVPN          │
                    │  SSH :2222 (key-only)               │
                    └──────────wlan0──────────────────────┘
                              │
                         WiFi + antenna
                              │
                         Home router
                              │
                          Internet
```

## Security layers

| # | Layer | Config |
|---|---|---|
| 1 | Routing / forwarding | `sysctl` ip_forward, netplan |
| 2 | Kernel hardening | [`sysctl.conf`](../configs/sysctl.conf) |
| 3 | Firewall | [`nftables.conf`](../configs/nftables.conf) |
| 4 | DNS privacy | Pi-hole + Unbound + DNSCrypt |
| 5 | Remote admin | [`sshd_config`](../configs/sshd_config) + Fail2Ban |
| 6 | VPN tunnel | [`wireguard-wg0.conf`](../configs/wireguard-wg0.conf) |

## Data path (normal operation)

1. Laptop sends DNS query → Pi-hole (filter) → Unbound (resolve) → DNSCrypt (DoH upstream)
2. Laptop sends HTTPS/other traffic → nftables FORWARD → `wg0` → VPN peer → Internet
3. ISP sees encrypted VPN UDP, not destination hostnames

## Data path (VPN down — kill-switch)

1. `wg0` interface goes down
2. `PreDown` removes temporary accept rules; `PostUp` reject on `wlan0` forward stays effective
3. No cleartext escape via `wlan0`

Configuration install details: [`configs/README.md`](../configs/README.md)
