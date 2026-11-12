# SnappyMail webmail: nginx + PHP-FPM on Alpine, UID 10001, read-only root, data in /data.
# Release 2.38.2 is pinned by SHA-256 (signature checked with the project key
# 1016E47079145542F8BA133548208BA13290F3EB when the pin was set). Update: new version + sha.
ARG SNAPPYMAIL_VERSION=2.38.2
ARG SNAPPYMAIL_SHA256=71f1d8a9065cc9cf7ddd064f5c47cc7b255cb70e6a56713647fc73d4b79e33ec

FROM docker.io/library/alpine:3.24 AS fetch
ARG SNAPPYMAIL_VERSION
ARG SNAPPYMAIL_SHA256
RUN apk add --no-cache curl
WORKDIR /dl
RUN curl -fsSLO "https://github.com/the-djmaze/snappymail/releases/download/v${SNAPPYMAIL_VERSION}/snappymail-${SNAPPYMAIL_VERSION}.tar.gz" \
    && echo "${SNAPPYMAIL_SHA256}  snappymail-${SNAPPYMAIL_VERSION}.tar.gz" | sha256sum -c - \
    && mkdir /app && tar xzf "snappymail-${SNAPPYMAIL_VERSION}.tar.gz" -C /app

FROM docker.io/library/alpine:3.24 AS base
RUN apk add --no-cache nginx php84 php84-fpm php84-ctype php84-curl php84-dom php84-iconv php84-intl \
      php84-mbstring php84-opcache php84-openssl php84-session php84-simplexml php84-sodium php84-xml php84-zlib php84-fileinfo php84-phar \
    && mkdir -p /etc/snappymail /data && chown 10001:10001 /data
COPY --from=fetch /app /app
RUN printf '<?php\ndefine("APP_DATA_FOLDER_PATH", "/data/");\n' > /app/include.php
COPY nginx.conf php-fpm.conf /etc/snappymail/
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh
EXPOSE 8080

FROM base AS test
RUN sh -n /usr/local/bin/entrypoint.sh \
    && php84 -l /app/include.php && php84 -l /app/index.php \
    && php-fpm84 -t -y /etc/snappymail/php-fpm.conf \
    && nginx -t -c /etc/snappymail/nginx.conf 2>&1 | grep -q "syntax is ok" \
    && SNAPPYMAIL_DATA=/tmp/d RENDER_ONLY=1 /usr/local/bin/entrypoint.sh | grep -q '"IMAP"' \
    && grep -q 'allow_admin_panel = Off' /tmp/d/_data_/_default_/configs/application.ini

FROM base AS runtime
USER 10001:10001
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
