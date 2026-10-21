# Pre-built binaries — cross-compiled outside the Supervisor: the HA
# Supervisor's Docker daemon cancels builds that pull the golang builder image
# (resource/timeout ceiling), so binaries are built on the release machine and
# COPY'd in per architecture.
#
# The Supervisor passes BUILD_ARCH (amd64 | aarch64) as a build arg, matching
# the `arch:` list in config.yaml. This repo carries one binary per arch:
#   allium-mesh-amd64 / allium-mesh-aarch64        (the Allium Mesh agent)
#   pair-agent-amd64  / pair-agent-aarch64         (the pairing helper)
FROM alpine:3.20
ARG BUILD_ARCH=amd64
ARG BUILD_VERSION
LABEL io.hass.version="${BUILD_VERSION}"

# Install Tor (for Hidden Service) and bash/curl/jq (for run.sh).
# bashio is not installed — run.sh guards its source with
# `if [ -f /usr/lib/bashio.sh ]` and uses jq for all config reads,
# so it works fine without it.
RUN apk add --no-cache tor bash curl jq ca-certificates

COPY allium-mesh-${BUILD_ARCH} /usr/local/bin/allium-mesh
# pair-agent: pairing-completion HTTP server on 127.0.0.1:9199 — lets the user
# claim this node's .onion into their allium.network account (the panel's
# Connect tab and the allium_connect_enabled option depend on it).
COPY pair-agent-${BUILD_ARCH} /usr/local/bin/pair-agent
COPY run.sh /run.sh
RUN chmod +x /usr/local/bin/allium-mesh /usr/local/bin/pair-agent /run.sh

# HA add-ons conventionally run as root inside the container — the container
# itself is the security boundary. The /data mount is root-owned by the
# Supervisor, so nobody:nobody cannot create directories or write files there.
ENTRYPOINT ["/run.sh"]
