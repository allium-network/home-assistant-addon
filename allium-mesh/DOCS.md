# Allium Mesh — Home Assistant Add-on (retired)

> ⚠️ **Retired.** For remote access to Home Assistant, install
> **[Allium Connect (Home Node)](https://github.com/allium-network/home-assistant-addon-connect)**
> instead. It can also run the Snowflake proxy (turn on "Help censored users").
> This add-on keeps working for existing installs, but gets no new features.

## What it does

Allium Mesh runs a Tor Snowflake proxy on your Home Assistant server, helping
people in censored countries bypass internet restrictions. In return, you get
a free .onion address for secure remote access to your Home Assistant.

## How it works

- **Snowflake Proxy**: Relays encrypted WebRTC traffic between censored users
  and the Tor network. Your server acts as a bridge — you never see or handle
  the traffic content.
- **Hidden Service**: Creates a Tor .onion address that routes directly to your
  Home Assistant web interface. Access your HA from anywhere using Tor Browser,
  without port forwarding or a domain name.

> **Looking for account-based remote access instead?** This add-on is the
> *anonymous, contribution-first* one (no account; remote access is Tor Browser
> via a `.onion` address). For fast native access to Home Assistant and your
> whole LAN from anywhere — registered on your allium.network account, still
> without opening a port — use the separate
> **[Allium Connect (Home Node)](https://github.com/allium-network/home-assistant-addon-connect)**
> add-on. The two can run side by side.

## Panel

The add-on has a dashboard (the "panel") in the HA sidebar:

- **Overview** — whether the Snowflake proxy is running, with a Stop/Resume
  button, and today's numbers.
- **Relay** — traffic, this month's usage against your cap, your `.onion`
  address (with a Copy button) and a network check.
- **Connect** — optionally link your `.onion` to your allium.network account:
  in the dashboard go to Services → Add service → Get pairing code, then paste the
  code here.
- **Settings** — your current settings, with a link to this add-on's
  Configuration tab.

**All settings are changed in the Configuration tab.** The panel only shows them.
The panel itself does three things: Stop/Resume the proxy (always available),
link your account, and copy your address.

**Need a new `.onion` address?** Uninstall and reinstall the add-on. The address
comes from a key in the add-on's private data, and reinstalling creates a new one.
Anyone who knew the old address can no longer use it.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `monthly_cap_gb` | 50 | Monthly bandwidth cap in GB for contributed traffic (1–1000) |
| `allow_middle_node` | false | Allow the relay to run as a Tor middle node (opens port 9001). When off, the add-on is pinned to Snowflake-only |
| `hidden_service.enabled` | true | Enable Tor Hidden Service for remote access |
| `hidden_service.port` | 8123 | Port of your Home Assistant web interface |
| `allium_connect_enabled` | true | Run the pairing helper so you can claim this node's .onion into your allium.network account (optional) |
| `allium_api_url` | `https://allium.network` | Allium API base URL — leave at the default unless you self-host |
| `network_integrity_testing` | false | Help detect misbehaving parts of the network by letting Allium run automated tests through your connection when needed |
| `relay_contribute` | false | Share spare relay capacity so other peers' devices can connect when they can't link directly |

### Bandwidth cap

`monthly_cap_gb` is enforced by the built-in safety governor: contributed bytes
(Snowflake, and the middle node if enabled) are counted continuously, and when
the monthly budget is used up, contribution pauses until the month resets —
your own remote access keeps working. The panel's Relay tab and the
`sensor.allium_mesh_bandwidth_*` entities show live usage against the cap.

### Network Integrity Testing

**Network Integrity Testing** is off by default. When on, Allium occasionally
sends small automated test requests through the Tor network from your connection
to help identify relays that tamper with traffic. This may briefly associate
your IP with network-testing traffic. No personal data is collected. You can
turn it off anytime.

### Contribute Relay Capacity

**Contribute Relay Capacity** is off by default, and is separate from Network
Integrity Testing above.

**What it does:** When on, your node forwards other peers' end-to-end-encrypted
traffic — sealed ciphertext you can never read — for the small share of mesh
connections that can't link two devices directly. Forwarding stays within your
configured bandwidth cap.

**Why turn it on:** Direct device-to-device links cost nobody, but a minority of
connections need a relay. Pitching in keeps the mesh free for everyone and earns
priority relays and more devices. Prefer not to? Your own connections are
unaffected; turning this off only stops your node carrying traffic for others.
You can turn it off anytime.

## Home Assistant Sensor Entities

When the add-on is running, Allium Mesh automatically creates Home Assistant
sensor entities that you can use in dashboards and automations:

| Entity | Type | Description |
|--------|------|-------------|
| `sensor.allium_mesh_status` | Sensor | `running`, `stopped`, or `cap_reached` |
| `sensor.allium_mesh_bandwidth_used_gb` | Sensor (GB) | Monthly bandwidth used so far |
| `sensor.allium_mesh_bandwidth_cap_gb` | Sensor (GB) | Configured monthly cap |
| `sensor.allium_mesh_connections_today` | Sensor | Connections served today |
| `binary_sensor.allium_mesh_active` | Binary Sensor | `on` when relay is active |
| `sensor.allium_mesh_risk_status` | Sensor | `safe`, `warn`, or `blocked` |
| `sensor.allium_mesh_onion_address` | Sensor | .onion address (in attributes) |

### Example automations

**Notify when bandwidth reaches 80%:**
```yaml
trigger:
  - platform: template
    value_template: >
      {{ (states('sensor.allium_mesh_bandwidth_used_gb') | float) /
         (states('sensor.allium_mesh_bandwidth_cap_gb') | float) > 0.8 }}
action:
  - service: notify.mobile_app
    data:
      message: "Allium Mesh: 80% of monthly bandwidth used"
```

**Flash a light when the relay is active:**
```yaml
trigger:
  - platform: state
    entity_id: binary_sensor.allium_mesh_active
    to: "on"
action:
  - service: light.turn_on
    target:
      entity_id: light.office_lamp
    data:
      color_name: green
```

## Middle-node mode

With `allow_middle_node: false` (the default) the add-on is hard-pinned to
Snowflake-only — it will never run a Tor relay, even if your network looks
suitable for one.

If `allow_middle_node: true` is set AND you map port `9001/tcp` in the add-on's
network settings, the add-on may run a Tor middle relay when the built-in
assessment recommends it. Your home IP address will then appear in Tor's public
relay list. This is legal in most jurisdictions but may attract attention from
your ISP. The panel displays a prominent warning card when middle-node mode is
active.

The risk engine checks your country and ISP before allowing middle-node mode.
If your country or ISP is flagged as high-risk, the mode change is blocked until
you explicitly acknowledge the warning.

## Security

- The Snowflake proxy never exposes inbound ports
- Traffic is end-to-end encrypted — you cannot inspect it
- The .onion address is cryptographically unique to your server
- No telemetry identifies you — stats are fully anonymous

## Persistent Data

The following data is stored in `/data/` and persists across restarts and updates:

- `tor/hidden_service/` — Your .onion keypair (CRITICAL: do not delete)
- `onion_address` — Your .onion hostname (for display)
