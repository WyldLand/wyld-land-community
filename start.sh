#!/bin/bash
# Wyld Land — private/self-host launcher (Linux)
# Run ./start.sh, then enter a name + password in the browser.
cd "$(dirname "$0")"

# Stop any previous run still in the background, so your settings (and the ports)
# start clean. Without this, an old server helper can keep running and ignore changes.
pkill -f 'wyld-local/wyld-local' 2>/dev/null
pkill -f 'gns-modified' 2>/dev/null
sleep 0.5

# Optional GM/admin. Set this to a username BEFORE that account is first created:
# whoever first logs in with this name becomes GM, permanently. Setting or changing
# it later does NOT promote an account that already exists.
ADMIN=""

echo "Starting Wyld Land (local)..."

if [ -n "$ADMIN" ]; then ADMINFLAG=(-admin "$ADMIN"); else ADMINFLAG=(); fi

./wyld-local/wyld-local-linux -client ./client -saves ./saves -secret-file ./secret.key "${ADMINFLAG[@]}" &
SHIM=$!

for i in $(seq 1 50); do [ -f ./secret.key ] && break; sleep 0.1; done
SECRET="$(cat ./secret.key 2>/dev/null)"

( cd server && WYLD_JWT_SECRET="$SECRET" SERVER_NUM=0 AUTH_SERVER_ADDRESS=http://localhost:3000 ./gns-modified-linux ) &
SRV=$!

trap 'echo; echo "Stopping..."; kill $SHIM $SRV 2>/dev/null' EXIT INT TERM HUP

sleep 2
( xdg-open "http://localhost:3000/dev.html" >/dev/null 2>&1 || true )

echo
echo "Wyld Land is running."
echo "  Game:  http://localhost:3000/dev.html  (click \"Login\")"
echo "  Keep this terminal open. Press Ctrl+C to stop the game."
wait
