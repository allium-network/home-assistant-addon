#!/usr/bin/env bash
set -euo pipefail

# Source bashio if available (HA add-on environment).
if [ -f /usr/lib/bashio.sh ]; then
    # shellcheck source=/dev/null
    source /usr/lib/bashio.sh
fi

# ── Read configuration from HA options.json ──────────────────────────────
CONFIG_PATH="/data/options.json"

if [ -f "$CONFIG_PATH" ]; then
    MONTHLY_CAP_GB=$(jq -r '.monthly_cap_gb // 50' "$CONFIG_PATH")
    # NOTE: jq's // treats an explicit `false` as empty, so `X // true` could
    # never be turned off — spell the default-true booleans out.
    HS_ENABLED=$(jq -r 'if .hidden_service.enabled == false then "false" else "true" end' "$CONFIG_PATH")
    HS_PORT=$(jq -r '.hidden_service.port // 8123' "$CONFIG_PATH")
    AC_ENABLED=$(jq -r 'if .allium_connect_enabled == false then "false" else "true" end' "$CONFIG_PATH")
    ALLIUM_API_URL=$(jq -r '.allium_api_url // "https://allium.network"' "$CONFIG_PATH")
    # Default OFF — becoming a publicly listed Tor relay is an explicit choice.
    ALLOW_MIDDLE_NODE=$(jq -r '.allow_middle_node // false' "$CONFIG_PATH")
    # Default OFF — probing only ever happens after explicit user opt-in.
    NETWORK_INTEGRITY_TESTING=$(jq -r '.network_integrity_testing // false' "$CONFIG_PATH")
    # Default OFF — relay capacity is shared only after explicit user opt-in.
    RELAY_CONTRIBUTE=$(jq -r '.relay_contribute // false' "$CONFIG_PATH")
else
    MONTHLY_CAP_GB=50
    HS_ENABLED=true
    HS_PORT=8123
    AC_ENABLED=true
    ALLIUM_API_URL="https://allium.network"
    ALLOW_MIDDLE_NODE=false
    NETWORK_INTEGRITY_TESTING=false
    RELAY_CONTRIBUTE=false
fi

# Installs from before 0.1.13 saved the old default, https://api.allium.network,
# in their options — a hostname that never existed, so pairing could not work.
# Map it to the real API base.
case "$ALLIUM_API_URL" in
    https://api.allium.network|https://api.allium.network/)
        echo "[allium-mesh] allium_api_url: replacing the retired default with https://allium.network"
        ALLIUM_API_URL="https://allium.network"
        ;;
esac

export ALLIUM_MONTHLY_CAP_GB="$MONTHLY_CAP_GB"
export ALLIUM_PLATFORM="hassio"
export ALLIUM_PANEL_PORT="8099"
# Settings have ONE home: this add-on's Configuration tab. The panel's write
# controls (change cap, reset counters) changed values the next restart put back,
# so they stay off; Stop/Resume and account linking work regardless.
export ALLIUM_PANEL_ALLOW_WRITE="false"

# The panel's "Open add-on settings" link needs this add-on's real slug (a
# repository install is "<repo-hash>_allium-mesh", not "local_allium_mesh").
if [ -n "${SUPERVISOR_TOKEN:-}" ]; then
    SLUG=$(curl -fsS --max-time 5 -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        http://supervisor/addons/self/info 2>/dev/null | jq -r '.data.slug // empty' || true)
    if [ -n "$SLUG" ]; then
        export ALLIUM_HA_ADDON_SLUG="$SLUG"
    fi
fi

# This add-on is retired (Allium Connect replaced it). Say so on every panel tab.
export ALLIUM_PANEL_NOTICE="Allium Mesh is retired. For remote access to Home Assistant, install the \"Allium Connect (Home Node)\" add-on. Your .onion address keeps working until you uninstall this add-on."
export ALLIUM_PANEL_NOTICE_URL="https://github.com/allium-network/home-assistant-addon-connect"
# Persist counters (sharing stats + monthly-cap tally) to /data, which survives
# add-on restarts AND updates — so a reboot no longer wipes the numbers or resets
# the monthly cap mid-month.
export ALLIUM_STATE_DIR="/data"

# ── Middle-node permission gate (default OFF) ────────────────────────────
# The agent auto-assesses the network and may RECOMMEND middle-node mode; with
# tor bundled in this image it would then start a publicly listed Tor relay.
# Unless the user explicitly allowed that, pin the agent to snowflake-only
# (ALLIUM_MODE=snowflake is honored as a hard pin). When allowed, leave the
# mode on auto-detect: the risk engine + assessment still gate the switch, and
# port 9001/tcp must be mapped in the add-on's network settings.
if [ "$ALLOW_MIDDLE_NODE" != "true" ]; then
    export ALLIUM_MODE="snowflake"
fi

# ── Network Integrity Testing opt-in (default OFF) ───────────────────────
# Only export the opt-in env var when the user has explicitly turned it on.
# When off, the variable is left unset and the agent defaults to disabled.
if [ "$NETWORK_INTEGRITY_TESTING" = "true" ]; then
    export ALLIUM_NETWORK_INTEGRITY_TESTING="true"
fi

# ── Relay Capacity Contribution opt-in (default OFF) ──────────────────────
# SEPARATE from Network Integrity Testing above (mission separation): this
# only shares spare relay bandwidth so other peers' devices can connect when
# they cannot link directly. Relays forward sealed ciphertext only. Always
# exported EXPLICITLY, true or false: when the variable is unset the agent
# defaults to contributing, so exporting only on opt-in made OFF a no-op.
if [ "$RELAY_CONTRIBUTE" = "true" ]; then
    export ALLIUM_MESH_RELAY_CONTRIBUTE="true"
else
    export ALLIUM_MESH_RELAY_CONTRIBUTE="false"
fi

# ── Start Tor Hidden Service (if enabled) ────────────────────────────────
if [ "$HS_ENABLED" = "true" ]; then
    echo "[allium-mesh] Starting Tor Hidden Service..."

    # Create torrc for Hidden Service only (no relay, no exit).
    mkdir -p /data/tor/hidden_service
    chmod 700 /data/tor/hidden_service
    cat > /tmp/torrc <<TORRC
SocksPort 0
HiddenServiceDir /data/tor/hidden_service
HiddenServicePort 80 homeassistant:${HS_PORT}
DataDirectory /tmp/tor-data
TORRC

    # Start Tor in background.
    mkdir -p /tmp/tor-data
    tor -f /tmp/torrc &
    TOR_PID=$!

    # Wait for .onion address to be generated (up to 30 seconds).
    TOR_STARTED=false
    for i in $(seq 1 30); do
        if [ -f /data/tor/hidden_service/hostname ]; then
            ONION_ADDR=$(cat /data/tor/hidden_service/hostname)
            echo "[allium-mesh] Tor Hidden Service ready: $ONION_ADDR"
            # Write for the panel to read.
            echo "$ONION_ADDR" > /data/onion_address
            TOR_STARTED=true
            break
        fi
        sleep 1
    done

    if [ "$TOR_STARTED" != "true" ]; then
        # Don't exit — allium-mesh relay still runs. Allium Connect will be skipped.
        echo "[allium-mesh] ERROR: Tor Hidden Service did not start within 30s — Allium Connect disabled"
    fi
fi

# ── Pass onion address to allium-mesh if available ───────────────────────
if [ -f /data/onion_address ]; then
    export ALLIUM_ONION_ADDRESS=$(cat /data/onion_address)
fi

# ── Start Allium Connect pair-agent (if enabled) ─────────────────────────
# The pair-agent accepts pairing tokens from the user and registers the
# hidden service with their allium.network account automatically.
# Guard on TOR_STARTED (not just /data/onion_address) so a stale address
# file from a previous run doesn't cause pair-agent to launch with a dead service.
if [ "$AC_ENABLED" = "true" ] && [ "${TOR_STARTED:-false}" = "true" ]; then
    if command -v pair-agent > /dev/null 2>&1; then
        echo "[allium-mesh] Starting Allium Connect pair-agent on 127.0.0.1:9199..."
        ALLIUM_PAIR_AGENT_ADDR="127.0.0.1:9199" \
        ALLIUM_API_URL="$ALLIUM_API_URL" \
        ALLIUM_ONION_ADDRESS="$(cat /data/onion_address)" \
        ALLIUM_TARGET_PORT="$HS_PORT" \
        ALLIUM_LABEL="Home Assistant" \
        ALLIUM_PLATFORM="homeassistant" \
        pair-agent &
        # The panel's Connect tab and the HA sensor bridge look the pair-agent
        # up here; their compiled-in default is the docker-compose hostname
        # (allium-connect-sidecar), which does not exist inside this container.
        export ALLIUM_CONNECT_SIDECAR_URL="http://127.0.0.1:9199"
    fi
fi

# ── Start allium-mesh agent ──────────────────────────────────────────────
echo "[allium-mesh] Starting Snowflake proxy..."
exec /usr/local/bin/allium-mesh
