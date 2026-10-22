#!/bin/sh
# Writes deploy/rtc_config.json (STUN/TURN servers sent to browsers) from deploy/.env.
set -eu

cd "$(dirname "$0")"

if [ ! -f .env ]; then
    echo "deploy/.env not found. Copy .env.example to .env and fill it in." >&2
    exit 1
fi

. ./.env

cat > rtc_config.json <<EOF
{
  "sdpSemantics": "unified-plan",
  "iceServers": [
    {
      "urls": "stun:${DOMAIN}:3478"
    },
    {
      "urls": [
        "turn:${DOMAIN}:3478?transport=udp",
        "turn:${DOMAIN}:3478?transport=tcp"
      ],
      "username": "${TURN_USER}",
      "credential": "${TURN_PASSWORD}"
    }
  ]
}
EOF

echo "Wrote deploy/rtc_config.json for ${DOMAIN}"
