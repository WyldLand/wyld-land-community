# Hosting Wyld Land on the Internet

> Advanced and optional. Playing locally or with friends on your LAN needs none of this
> — see `README.md`. Running a public server means TLS, a domain name, and an
> internet-facing service that you maintain at your own risk.

## Overview

Two programs serve the game:

- **`wyld-local`** (the shim) — serves the browser client and handles login,
  matchmaking, and saves over HTTP (port `3000`).
- **`gns-modified`** (the game server) — the realtime gameplay connection
  (WebSocket on `2054`, WebTransport on `4433`).

They share a per-host secret (`secret.key`, passed to the server as `WYLD_JWT_SECRET`,
created automatically on first run). The game server trusts any validly-signed token, so
that secret is your entire security boundary — keep it private and unique to your server.

A public server must be served over **HTTPS**, and an HTTPS page can only open a **secure**
gameplay connection (`wss://` or WebTransport).

**You will need:** a Linux host with a public IP, and a **domain name** pointed at it (TLS
certificates are issued for names, not bare IP addresses).

Pick one:

- **Approach A — WebSocket over TLS.** Recommended and much simpler. A reverse proxy
  ([Caddy](https://caddyserver.com)) handles TLS for everything.
- **Approach B — WebTransport.** Adds a lower-latency HTTP/3 transport for browsers that
  support it, on top of Approach A. More setup, what Wyld Land ran in production.

---

## Approach A — WebSocket over TLS

Caddy terminates TLS on port `443` and forwards requests to the shim and game server,
which stay on `localhost`. Caddy obtains and auto-renews a free Let's Encrypt certificate.

1. **Point your domain at the server.** Create a DNS `A` record (for example
   `play.example.com`) pointing at your server's public IP.

2. **Install Caddy** on the host — see <https://caddyserver.com/docs/install>.

3. **Run the shim and game server**, both bound to `localhost`, sharing the secret:
   ```bash
   ./wyld-local/wyld-local -client ./client -saves ./saves -secret-file ./secret.key -api 127.0.0.1:3000 &
   ( cd server && WYLD_JWT_SECRET="$(cat ../secret.key)" SERVER_NUM=0 \
       AUTH_SERVER_ADDRESS=http://localhost:3000 ./gns-modified-linux )
   ```

4. **Configure Caddy.** Put this in `/etc/caddy/Caddyfile`, with your own domain:
   ```
   play.example.com {
       reverse_proxy /ws0 localhost:2054   # gameplay WebSocket
       reverse_proxy localhost:3000        # client, login, matchmaking, saves
   }
   ```

5. **Start Caddy** (`sudo systemctl restart caddy`). It fetches a TLS certificate on the
   first request and renews it automatically from then on.

6. **Open the firewall** for inbound `443/tcp` (and `80/tcp`, used for the certificate
   challenge). Leave `3000`, `2054`, and `4433` closed to the outside — Caddy reaches the
   backend over `localhost`.

Players visit **`https://play.example.com/dev.html`** and log in with a name and password.
The editor is at **`https://play.example.com/editor.html`**.

---

## Approach B — WebTransport

WebTransport (HTTP/3 over QUIC) is a lower-latency transport, and is what Wyld Land used
in production. Browsers that support it connect directly to the game server on port
`4433`; browsers that don't automatically use the WebSocket connection from Approach A.

Set up **Approach A first**, then:

1. **Turn on WebTransport in the client.** In `client/bin/client.min.js`, change:
   ```
   supportsWebtransport(){return !1
   ```
   to:
   ```
   supportsWebtransport(){return window.WebTransport!=null
   ```
   Confirm the file still parses afterward: `node --check client/bin/client.min.js`.

2. **Give the game server a TLS certificate** for your domain. The server reads
   `server/certificate.pem` and `server/certificate.key` at startup. You can issue 
   one with `certbot` by Let's Encrypt, and copy them in as those two filenames.

3. **Open UDP `4433`** in your firewall (WebTransport runs over QUIC, which is UDP).

4. **Restart the game server** so it loads the certificate.

5. **Keep the certificate fresh.** The server reads it only at startup, and Let's Encrypt
   certificates expire about every 90 days. Automate copying the renewed certificate into
   `server/certificate.{pem,key}` and restarting the game server (a cron job, or a hook on
   Caddy's renewal).

---

## Security & operations

- **Keep `secret.key` private and unique to your server.** Anyone who has it can
  impersonate any account, including GM.
- **GM access:** set `ADMIN="YourName"` in the launcher so only your account has admin
  powers; everyone else is a normal player.
- **Passwords** are protected in transit only by TLS — never run a public server without
  it. Player saves are encrypted at rest with each player's own password.
- **Back up the `saves/` folder** — it holds every player's character.
- **There is no built-in rate limiting or abuse protection.** Keep the host patched and
  use standard measures (firewall, fail2ban, Caddy request limits).
- **Scale:** one shim and one game server process handle a small community comfortably.
  All overworld players share one world; dungeons and the editor's arena run as separate
  instances. Saves are local files — there is no database.

---

*Provided as-is. Running a public server is your responsibility; see `README.md` and
`LICENSE`.*
