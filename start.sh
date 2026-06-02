#!/bin/bash
# Wyld Land — private/self-host launcher (Linux)
# Run ./start.sh, then enter a name + password in the browser.
cd "$(dirname "$0")"

# Optional: set this to your chosen username to grant yourself GM (admin).
ADMIN=""

echo "Starting Wyld Land (local)..."

if [ -n "$ADMIN" ]; then ADMINFLAG=(-admin "$ADMIN"); else ADMINFLAG=(); fi

./wyld-local/wyld-local-linux -client ./client -saves ./saves -secret-file ./secret.key "${ADMINFLAG[@]}" &
SHIM=$!

for i in $(seq 1 50); do [ -f ./secret.key ] && break; sleep 0.1; done
SECRET="$(cat ./secret.key 2>/dev/null)"

( cd server && WYLD_JWT_SECRET="$SECRET" SERVER_NUM=0 AUTH_SERVER_ADDRESS=http://localhost:3000 ./gns-modified-linux ) &
SRV=$!

trap 'echo; echo "Stopping..."; kill $SHIM $SRV 2>/dev/null' EXIT INT TERM

sleep 2
( xdg-open "http://localhost:3000/dev.html" >/dev/null 2>&1 || true )

echo
echo "Wyld Land is running."
echo "  Game:  http://localhost:3000/dev.html  (click \"Login\")"
echo "  Keep this terminal open. Press Ctrl+C to stop the game."
wait
