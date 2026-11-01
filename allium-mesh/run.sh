#!/bin/sh
# Allium Mesh is retired. This final release runs nothing: no Snowflake proxy,
# no Tor hidden service, no panel. It explains what to do and exits.
cat <<'MSG'
------------------------------------------------------------------
Allium Mesh is retired and no longer runs anything.

  * The Snowflake proxy is off. This add-on no longer relays traffic.
  * The .onion address for Home Assistant is off.

For remote access to Home Assistant, install "Allium Connect (Home Node)":
  https://github.com/allium-network/home-assistant-addon-connect

You can safely uninstall this add-on:
  Settings > Add-ons > Allium Mesh (retired) > Uninstall
------------------------------------------------------------------
MSG
exit 0
