---
name: home-network-routing
description: Use when troubleshooting or changing home routing, Internet access, double NAT, port forwarding, DHCP, DNS, IPv4 or IPv6, Wi-Fi routing, the Netgear Nighthawk, the AT&T BGW320 gateway, routerlogin.net, 10.0.0.1, or 192.168.1.254.
---

# Home Network Routing

Use this skill for any task involving the home Internet connection, router configuration, NAT, DHCP, DNS, firewalling, port forwarding, or connectivity through the Netgear and AT&T routers. Start with read-only inspection and verify the current topology before proposing or making changes.

## Topology

The home network has two routers:

```text
AT&T fiber
  -> HUMAX BGW320-500 gateway
     WAN: public AT&T IPv4 and native IPv6
     LAN: 192.168.1.0/24
     Management: https://192.168.1.254
  -> Netgear Nighthawk R6700AX
     WAN: DHCP address on 192.168.1.0/24
     LAN: 10.0.0.0/24
     Management: https://10.0.0.1
  -> Home clients and homelab
```

As observed on 2026-07-21:

- The BGW320 had `IP Passthrough` off, `Cascaded Router` disabled, packet filtering on, and its advanced firewall on.
- The BGW320 DHCP server was enabled and the Nighthawk was its only active Ethernet client, connected to port 3 at 1 Gbps.
- Both BGW320 Wi-Fi radios were disabled. The Nighthawk provided the home Wi-Fi networks.
- The Nighthawk WAN used a private `192.168.1.x` address while its LAN was `10.0.0.0/24`, producing IPv4 double NAT.
- The Nighthawk used DHCP for its WAN and had DHCP enabled on its LAN.

Treat addresses assigned by DHCP, public addresses, firmware versions, counters, and device inventories as dynamic. Re-read them during each investigation rather than relying on the snapshot.

## Credentials

Credentials are provided only through environment variables:

| Router | Variable | Purpose |
| --- | --- | --- |
| Netgear | `ROUTER_USERNAME` | Nighthawk administrative username, normally `admin` |
| Netgear | `ROUTER_PASSWORD` | Nighthawk administrative password |
| AT&T | `ATT_ROUTER_ACCESS_CODE` | BGW320 device access code required for protected changes |

Never print these values, include them in reports, save them in this repository, or place literal values in command text. Check only whether a variable is populated:

```bash
if [[ -n "$ROUTER_USERNAME" && -n "$ROUTER_PASSWORD" ]]; then
  printf 'Netgear credentials available\n'
fi

if [[ -n "$ATT_ROUTER_ACCESS_CODE" ]]; then
  printf 'AT&T access code available\n'
fi
```

Environment changes made after OpenCode starts are not visible to its shell tools. If a variable is missing, ask the user to restart OpenCode from the shell where it was exported. Do not ask the user to paste a secret into chat.

## Netgear Nighthawk

### Discovery

The Nighthawk is an `R6700AX`. Its unauthenticated identification endpoint is:

```bash
curl --silent --show-error --max-time 10 \
  http://10.0.0.1/currentsetting.htm
```

This reports the current model, firmware, region, Internet status, SOAP version, and login method without exposing configuration secrets.

Ports 80 and 443 serve the management interface. Port 53 provides DNS. SSH and Telnet were not exposed when last checked.

### Authenticated Reads

Do not assume HTTP Basic authentication works. On the observed firmware, `curl --user` against the web UI returned misleading redirects or `401`, while the supported SOAP v2 login flow succeeded.

The SOAP endpoint is:

```text
https://10.0.0.1/soap/server_sa/
```

SOAP v2 authentication works as follows:

1. POST `DeviceConfig:1#SOAPLogin` with `ROUTER_USERNAME` and `ROUTER_PASSWORD` in the SOAP body.
2. Include a SOAP `SessionID` header. Netgear clients commonly use `A7D88AE69687E58D9A00`.
3. Capture the response's `Set-Cookie` value.
4. Send that cookie with subsequent read-only SOAP actions.
5. Inspect the SOAP body's `ResponseCode`; HTTP `200` with SOAP `ResponseCode 401` is an authentication failure. `000` or `0000` indicates success.

The proven client implementation is `MatMaul/pynetgear`. During the initial investigation it was checked out at `~/.local/repo-exploration/pynetgear`; relevant protocol code is in `pynetgear/router.py` and `pynetgear/const.py`. If that checkout is absent, fetch the canonical repository or use a packaged `pynetgear` version. Do not copy credentials into source code.

Useful read-only methods include:

| Method | Information |
| --- | --- |
| `get_info()` | Model, firmware, hardware, and device information |
| `get_lan_config_sec_info()` | LAN address, subnet, and DHCP state |
| `get_wan_ip_con_info()` | WAN addressing, gateway, DNS, and MTU |
| `get_system_info()` | CPU, memory, and flash utilization |
| `check_ethernet_link()` | WAN Ethernet status |
| `get_device_config_info()` | Time zone and general configuration state |
| `get_2g_info()` / `get_5g_info()` | Wi-Fi state, SSID, channel, mode, and security type |
| `get_2g_guest_access_enabled()` / `get_5g_guest_access_enabled()` | Guest network state |
| `get_qos_enable_status()` | QoS state |
| `get_smart_connect_enabled()` | Smart Connect state |
| `get_attached_devices()` | Client inventory; this timed out on the R6700AX during initial inspection |

Do not call methods beginning with `set_`, `enable_`, `update_`, `config_`, or `reboot` during inspection. Do not query WPA security key methods unless the user explicitly needs the key; ordinary Wi-Fi diagnostics do not require disclosing it.

The router uses a self-signed certificate for `routerlogin.net`, so local requests may require disabled certificate verification. Limit this exception to the known local management address and do not generalize it to Internet endpoints.

## AT&T BGW320

The upstream router is a HUMAX `BGW320-500` at:

```text
https://192.168.1.254
```

It runs a Lighttpd CGI management interface. The following status pages were proven readable with unauthenticated HTTPS `GET` requests:

| Path | Information |
| --- | --- |
| `/cgi-bin/home.ha` | Broadband, Wi-Fi, voice, and attached-device summary |
| `/cgi-bin/sysinfo.ha` | Model, firmware, uptime, and hardware information |
| `/cgi-bin/broadbandstatistics.ha` | Fiber, GPON, public WAN, DNS, MTU, IPv6, link speed, errors, and drops |
| `/cgi-bin/lanstatistics.ha` | LAN subnet, DHCP pools, interfaces, IP Passthrough status, IPv6, and Ethernet ports |
| `/cgi-bin/firewall.ha` | Packet filter, IP Passthrough, NAT default server, and advanced firewall status |

Example read:

```bash
curl --insecure --silent --show-error --max-time 15 \
  https://192.168.1.254/cgi-bin/lanstatistics.ha
```

Prefer HTTPS even though HTTP is available. The gateway uses a local certificate, hence the narrowly scoped `--insecure` option.

The public pages can include public IP addresses, IPv6 prefixes, MAC addresses, serial numbers, SSIDs, device names, and nonces. Extract only fields needed for the task and redact sensitive identifiers from reports. A hidden `nonce` or a `SessionID` cookie is not proof of authentication and must not be reused blindly.

### Protected Changes

`ATT_ROUTER_ACCESS_CODE` is expected to be required for protected configuration changes, but the exact authentication POST flow has not yet been validated. Do not guess field names or POST the access code speculatively.

Before any approved BGW320 change:

1. Start a fresh HTTPS session and retain its `SessionID` cookie.
2. GET the exact target page and inspect its current form action, fields, nonce, and existing values.
3. Determine how that firmware requests and validates the device access code.
4. Explain the expected routing impact and obtain confirmation for disruptive changes.
5. Submit the smallest possible change, then re-read status from both routers and test client connectivity.

Never POST forms whose actions include restart, clear statistics, reset, or configuration endpoints merely to discover behavior.

## Double NAT And IP Passthrough

With IP Passthrough off, both routers perform NAT. This can affect inbound port forwarding, peer-to-peer applications, gaming NAT classification, VPNs, NAT loopback, and troubleshooting because rules may be required on both routers.

The usual design when the Nighthawk is intended to be the primary router is BGW320 IP Passthrough targeted to the Nighthawk. Do not enable it casually. It can:

- Replace the Nighthawk's private WAN lease with the public IPv4 address.
- Interrupt Internet access while leases and NAT state change.
- Change which device is responsible for inbound firewalling and port forwarding.
- Require selecting the Nighthawk by its WAN MAC address and renewing or rebooting equipment.
- Affect remote access to the home network.

Before proposing IP Passthrough, establish the user's goal and inspect both routers' current WAN, firewall, DHCP, port-forwarding, and IPv6 state. Ask for explicit confirmation immediately before applying it.

## Investigation Workflow

1. Confirm the workstation is on `10.0.0.0/24` and that `10.0.0.1` and `192.168.1.254` are reachable.
2. Read `/currentsetting.htm` from the Nighthawk and the BGW320 system/status pages to detect model, firmware, and topology changes.
3. Read Nighthawk LAN and WAN settings through authenticated SOAP.
4. Read BGW320 broadband, LAN, and firewall status through unauthenticated HTTPS.
5. Determine whether the problem is on a client, the Nighthawk LAN/Wi-Fi, the inter-router link, BGW320 NAT/firewall, fiber/GPON, DNS, or the wider Internet.
6. Test from the client outward: local route, router reachability, DNS, public IP connectivity, and application-specific ports.
7. Present evidence and the smallest proposed change. Do not mutate either router unless the user asked for that change.
8. After an approved change, verify both management interfaces remain reachable and test DNS, IPv4, IPv6, and the original failing workflow.

## Safety

- Default to read-only `GET` and SOAP `Get*` actions.
- Never expose router passwords, access codes, Wi-Fi keys, cookies, nonces, public addresses, serial numbers, or full MAC addresses in reports unless the user specifically needs them.
- Do not reboot, reset, update firmware, alter DHCP subnets, enable IP Passthrough, change Wi-Fi, or modify firewall/NAT rules without explicit user approval.
- Avoid repeated failed login attempts because both routers may trigger lockout or password-recovery behavior.
- Preserve management access. Routing changes can disconnect the machine running OpenCode and prevent automatic verification or rollback.
- Re-read current settings immediately before a change; firmware updates may alter CGI fields, SOAP behavior, and authentication flows.
