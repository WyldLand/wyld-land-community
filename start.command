#!/bin/bash
# Wyld Land — private/self-host launcher (macOS)
# Double-click this file, then enter a name + password in the browser.
cd "$(dirname "$0")"

# macOS stamps a "quarantine" flag on everything unzipped from a download, which
# makes Gatekeeper nag ("Allow Anyway") for each unsigned binary. Clearing that flag
# is a per-user operation: no password or sudo needed. We strip it from this whole
# folder so the helpers below launch without prompts. (You may still see ONE prompt
# for this start.command file the first time you double-click it — that's expected.)
# Also re-set the executable bit, which zip extraction sometimes drops.
xattr -dr com.apple.quarantine "$PWD" 2>/dev/null
chmod +x ./wyld-local/wyld-local ./server/gns-modified 2>/dev/null

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

# Local services: serves the client + handles login/saves on port 3000.
# Generates ./secret.key (the per-host JWT secret) on first run.
./wyld-local/wyld-local -client ./client -saves ./saves -secret-file ./secret.key "${ADMINFLAG[@]}" &
SHIM=$!

# Wait for the secret file, then start the game server with the same secret.
for i in $(seq 1 50); do [ -f ./secret.key ] && break; sleep 0.1; done
SECRET="$(cat ./secret.key 2>/dev/null)"

( cd server && WYLD_JWT_SECRET="$SECRET" SERVER_NUM=0 AUTH_SERVER_ADDRESS=http://localhost:3000 ./gns-modified ) &
SRV=$!

trap 'echo; echo "Stopping..."; kill $SHIM $SRV 2>/dev/null' EXIT INT TERM HUP

sleep 2
open "http://localhost:3000/dev.html"

echo
echo "Wyld Land is running."
echo "  Game:  http://localhost:3000/dev.html  (click \"Login\")"
echo "  Keep this window open. Press Ctrl+C here to stop the game."
wait
