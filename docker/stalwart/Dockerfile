# Stalwart mail server (SMTP/IMAP/JMAP), official image pinned by digest, run as UID 10001 with a
# read-only root filesystem. Data lives in MariaDB (chart `database`), nothing on local disk.
# Update: new tag + digest (`docker buildx imagetools inspect stalwartlabs/stalwart:<tag>`).
FROM docker.io/stalwartlabs/stalwart:v1.1.1@sha256:5ebdf474b237161742fe4309396af4ae8797c938e8e6eb7e2d4837332c4f9851 AS base
USER root
# No file capabilities: with allowPrivilegeEscalation=false the binary would not start. The server
# listens on unprivileged ports behind Traefik.
RUN setcap -r /usr/local/bin/stalwart \
    && userdel stalwart \
    && groupadd -r -g 10001 stalwart && useradd -r -u 10001 -g 10001 -s /usr/sbin/nologin -M stalwart \
    && mkdir -p /var/lib/stalwart && chown 10001:10001 /var/lib/stalwart
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh
ENV STALWART_HEALTHCHECK_URL=http://127.0.0.1:8080/healthz/live

FROM base AS test
RUN sh -n /usr/local/bin/entrypoint.sh \
    && DB_HOST=db DB_NAME=n DB_USER=u DB_PASSWORD=secret RENDER_ONLY=1 STALWART_CONFIG=/tmp/c.json \
       /usr/local/bin/entrypoint.sh | tee /tmp/out.json \
    && grep -q '"@type":"EnvironmentVariable"' /tmp/out.json && ! grep -q secret /tmp/out.json \
    && /usr/local/bin/stalwart --help >/dev/null

FROM base AS runtime
USER 10001:10001
WORKDIR /var/lib/stalwart
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
