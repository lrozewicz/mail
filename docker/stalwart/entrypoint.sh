#!/bin/sh
# Renders /tmp/config.json (the local Stalwart config: only the data store) from the DB_* variables
# that the platform chart sets for the MariaDB of this release, then starts Stalwart.
# The password is never written to disk: Stalwart reads it from the DB_PASSWORD variable.
set -eu

: "${DB_HOST:?DB_HOST is required}"
: "${DB_NAME:?DB_NAME is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"
CONFIG="${STALWART_CONFIG:-/tmp/config.json}"

cat > "$CONFIG" <<JSON
{"@type":"MySql","host":"${DB_HOST}","port":${DB_PORT:-3306},"database":"${DB_NAME}","authUsername":"${DB_USER}","authSecret":{"@type":"EnvironmentVariable","variableName":"DB_PASSWORD"},"useTls":false,"allowInvalidCerts":false}
JSON

[ "${RENDER_ONLY:-}" = "1" ] && { cat "$CONFIG"; exit 0; }
exec /usr/local/bin/stalwart --config "$CONFIG"
