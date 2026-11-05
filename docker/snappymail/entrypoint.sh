#!/bin/sh
# Seeds the SnappyMail data folder (/data) declaratively, then starts php-fpm and nginx.
#  - the admin panel is OFF unless SNAPPYMAIL_ADMIN=1 (domains are configured from env, not the UI);
#  - one domain file points at the mail server: IMAP_HOST/PORT, SMTP_HOST/PORT (+ *_TYPE:
#    0 none, 1 TLS, 2 STARTTLS). SnappyMail only connects to servers defined here.
set -eu

DATA="${SNAPPYMAIL_DATA:-/data}/_data_/_default_"
IMAP_HOST="${IMAP_HOST:-stalwart}"; IMAP_PORT="${IMAP_PORT:-143}"; IMAP_TYPE="${IMAP_TYPE:-2}"
SMTP_HOST="${SMTP_HOST:-stalwart}"; SMTP_PORT="${SMTP_PORT:-587}"; SMTP_TYPE="${SMTP_TYPE:-2}"
VERIFY="${MAIL_TLS_VERIFY:-false}"      # the in-cluster certificate does not carry the Service name
if [ "${SNAPPYMAIL_ADMIN:-0}" = "1" ]; then ADMIN=On; else ADMIN=Off; fi

mkdir -p "$DATA/domains" "$DATA/configs" /tmp/nginx-body

cat > "$DATA/domains/default.json" <<JSON
{"IMAP":{"host":"${IMAP_HOST}","port":${IMAP_PORT},"type":${IMAP_TYPE},"timeout":300,"shortLogin":false,"lowerLogin":true,"sasl":["SCRAM-SHA-256","SCRAM-SHA-1","PLAIN"],"ssl":{"verify_peer":${VERIFY},"verify_peer_name":${VERIFY},"allow_self_signed":false,"SNI_enabled":true,"disable_compression":true,"security_level":1},"use_expunge_all_on_delete":false,"fast_simple_search":true,"force_select":false,"message_all_headers":false,"message_list_limit":10000,"disable_list_status":false,"disable_metadata":false,"disable_move":false,"disable_sort":false,"disable_thread":false,"disabled_capabilities":[]},"SMTP":{"host":"${SMTP_HOST}","port":${SMTP_PORT},"type":${SMTP_TYPE},"timeout":60,"shortLogin":false,"lowerLogin":true,"sasl":["SCRAM-SHA-256","SCRAM-SHA-1","PLAIN"],"ssl":{"verify_peer":${VERIFY},"verify_peer_name":${VERIFY},"allow_self_signed":false,"SNI_enabled":true,"disable_compression":true,"security_level":1},"useAuth":true,"setSender":false,"usePhpMail":false},"Sieve":{"host":"${IMAP_HOST}","port":4190,"type":2,"timeout":10,"shortLogin":false,"lowerLogin":true,"sasl":["PLAIN"],"ssl":{"verify_peer":${VERIFY},"verify_peer_name":${VERIFY},"allow_self_signed":false,"SNI_enabled":true,"disable_compression":true,"security_level":1},"enabled":false},"whiteList":""}
JSON

# Minimal application.ini; SnappyMail fills in the rest with defaults and keeps what is set here.
cat > "$DATA/configs/application.ini" <<INI
[webmail]
title = "${WEBMAIL_TITLE:-Webmail}"
allow_languages_on_settings = On
[security]
allow_admin_panel = ${ADMIN}
force_https = On
custom_server_signature = ""
INI

[ "${RENDER_ONLY:-}" = "1" ] && { cat "$DATA/domains/default.json"; exit 0; }

# php-fpm in the background, nginx in the foreground; if either dies the container exits.
php-fpm84 -F -y /etc/snappymail/php-fpm.conf &
PHP=$!
nginx -e /dev/stderr -g 'daemon off;' -c /etc/snappymail/nginx.conf &
NGINX=$!
trap 'kill $PHP $NGINX 2>/dev/null' TERM INT
while kill -0 "$PHP" 2>/dev/null && kill -0 "$NGINX" 2>/dev/null; do sleep 2 & wait $!; done
kill "$PHP" "$NGINX" 2>/dev/null || true
exit 1
