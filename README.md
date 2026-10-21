# Allium Mesh — Home Assistant Add-on Repository

> **Help censored internet users. Get free `.onion` remote access in return.**

This repository contains the **Allium Mesh** add-on: it runs a Tor Snowflake
proxy on your Home Assistant server — helping people in censored countries
reach the open internet — and in return gives you a free `.onion` address for
secure remote access to Home Assistant via Tor Browser, with no port
forwarding, no DDNS and no account.

## How it works

- **Snowflake proxy**: relays encrypted WebRTC traffic between censored users
  and the Tor network, within your configured monthly bandwidth cap. You never
  see or handle traffic content.
- **Hidden service**: a Tor `.onion` address that routes to your Home Assistant
  web interface. Open it in Tor Browser from anywhere.
- **Panel + sensors**: a sidebar dashboard and `sensor.allium_mesh_*` entities
  for automations (bandwidth used, connections helped, relay status).

Everything is anonymous — no account needed. Optionally, pair the `.onion`
with an [allium.network](https://allium.network) account to see it in your
dashboard.

## This is NOT the "Allium Connect" add-on

Both add-ons exist, and they do different jobs:

| | **Allium Mesh** — this repo | **[Allium Connect (Home Node)](https://github.com/allium-network/home-assistant-addon-connect)** |
|---|---|---|
| Account | No account, fully anonymous | Yes — registers on your allium.network account |
| Main job | Contribute a Tor Snowflake proxy; free `.onion` remote access in return | Reach HA + your LAN from anywhere (fast WireGuard tunnels, named services) |
| Remote access | Tor Browser via a `.onion` address | Native apps, direct P2P speed |
| Contribution | The point of the add-on | Optional |

Run one or both — they don't conflict.

## Installation

1. In Home Assistant: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**,
   add this repository's URL.
2. Install **Allium Mesh** and start it.
3. The panel appears in the HA sidebar; your `.onion` address is shown there.

Full option reference and troubleshooting: see the add-on's
[DOCS.md](allium-mesh/DOCS.md).
