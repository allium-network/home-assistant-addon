# Allium Mesh is retired. The final image carries only the notice script:
# no agent binary, no Tor, nothing that relays traffic.
FROM alpine:3.20
ARG BUILD_VERSION
LABEL io.hass.version="${BUILD_VERSION}"

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
