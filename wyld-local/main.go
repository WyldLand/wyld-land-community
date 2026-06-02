// wyld-local: the self-host shim for Wyld Land.
//
// It serves the browser client as static files and replaces the Wyld Land cloud
// auth/persistence tier with local behavior on a single port:
//
//	GET  /serverlist                                 -> server dropdown source
//	GET  /auth/{provider}                            -> local username/password login form
//	POST /auth/local/submit                          -> create/verify account, start session
//	GET  /matchmaker/queue/{srv}/{q}/{mm}/{session}  -> mints the match JWT
//	POST /server/inventory/save/{id}                 -> encrypted save (saves/inventory-{id}.enc)
//	GET  /server/inventory/fetch/{id}                -> decrypted, or "null"
//	POST /server/characters/save/{id}                -> encrypted save (saves/character-{id}.enc)
//	GET  /server/characters/fetch/{id}               -> decrypted, or "null"
//	GET  /server/matchstatus/...                     -> 200 no-op
//	/* everything else */                            -> static client files
//
// Identity model: a username is an account; the password is the encryption key
// for that account's save files. There is no password recovery — lose it and
// the save is unreadable (by design). Accounts get IDs >= 1000 (never GM); an
// optional -admin username maps to ID 1 (GM, in dev mode).
//
// Security note: this is only meaningful when the game server runs with a
// per-host WYLD_JWT_SECRET (see -secret-file). With the shipped default secret,
// tokens are forgeable — fine for single-player, not for a shared server.
//
// Stdlib only (crypto/pbkdf2 + AES-GCM, hand-rolled HS256).
package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/pbkdf2"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"html"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

var (
	apiAddr    = flag.String("api", ":3000", "address for the API + static server")
	clientDir  = flag.String("client", "../client", "directory containing the browser client")
	savesDir   = flag.String("saves", "../saves", "directory for local save files")
	secretFile = flag.String("secret-file", "../secret.key", "per-host JWT secret file (auto-generated if missing)")
	adminUser  = flag.String("admin", "", "username granted GM (maps to account ID 1)")
)

const (
	defaultSecret  = "WYLD_SELFHOST_LOCAL_v1_3f8a2c91d7" // matches server fallback
	verifierConst  = "wyld-selfhost-verifier-v1"
	firstAccountID = 1000 // normal accounts start here; 1/45/418/517 are GM
	kdfIters       = 200_000
)

var (
	jwtSecret  []byte
	unameRe    = regexp.MustCompile(`^[a-zA-Z0-9_-]{3,20}$`)
	accMu      sync.Mutex
	accounts   = accountsFile{NextID: firstAccountID, Users: map[string]accountMeta{}}
	sessMu     sync.Mutex
	sessions   = map[string]*session{}
	sessByAcct = map[int]*session{}
)

type accountMeta struct {
	ID      int    `json:"id"`
	Salt    string `json:"salt"`    // hex
	Display string `json:"display"` // original-case name, set at registration
}

type accountsFile struct {
	NextID int                    `json:"nextId"`
	Users  map[string]accountMeta `json:"users"`
}

type session struct {
	Username  string
	AccountID int
	Key       []byte // 32-byte AES key derived from the password
}

func main() {
	flag.Parse()

	if err := os.MkdirAll(*savesDir, 0o755); err != nil {
		log.Fatalf("cannot create saves dir %q: %v", *savesDir, err)
	}
	jwtSecret = loadOrCreateSecret(*secretFile)
	loadAccounts()

	mux := http.NewServeMux()
	mux.HandleFunc("/serverlist", withLog(handleServerList))
	mux.HandleFunc("/auth/local/submit", withLog(handleAuthSubmit))
	mux.HandleFunc("/auth/", withLog(handleAuthForm))
	mux.HandleFunc("/gametokenfromstore/", withLog(handleGuest)) // editor guest login
	mux.HandleFunc("/matchmaker/queue/", withLog(handleMatchmaker))
	mux.HandleFunc("/server/inventory/save/", withLog(handleSave("inventory")))
	mux.HandleFunc("/server/inventory/fetch/", withLog(handleFetch("inventory")))
	mux.HandleFunc("/server/characters/save/", withLog(handleSave("character")))
	mux.HandleFunc("/server/characters/fetch/", withLog(handleFetch("character")))
	mux.HandleFunc("/server/matchstatus/", withLog(handleNoOp))

	fs := http.FileServer(http.Dir(*clientDir))
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			http.Redirect(w, r, "/dev.html", http.StatusFound)
			return
		}
		fs.ServeHTTP(w, r)
	})

	log.Printf("wyld-local listening on %s", *apiAddr)
	log.Printf("  client: %s   saves: %s", abs(*clientDir), abs(*savesDir))
	if *adminUser != "" {
		log.Printf("  admin (GM) username: %q", *adminUser)
	}
	log.Printf("  open http://localhost%s/dev.html and click \"Login\"", portOnly(*apiAddr))
	log.Fatal(http.ListenAndServe(*apiAddr, mux))
}

// ---- login / matchmaking ----

func handleServerList(w http.ResponseWriter, r *http.Request) {
	// "localhost" shows in the game; "editor" shows in the boss editor (each
	// client filters the list by name). Both point at the same local server.
	writeJSON(w, map[string]any{"servers": map[string]int{"localhost": 1, "editor": 1}})
}

// handleGuest answers the editor's "Login as Guest" button. The returned string
// is used as the account token; the Arena matchmaker branch ignores its value.
func handleGuest(w http.ResponseWriter, r *http.Request) {
	cors(w)
	io.WriteString(w, "guest")
}

// handleAuthForm serves the local login page in the popup the client opens
// (repurposed from the old Steam/Discord OAuth popup).
func handleAuthForm(w http.ResponseWriter, r *http.Request) {
	renderForm(w, "")
}

func handleAuthSubmit(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		renderForm(w, "Bad form submission.")
		return
	}
	orig := strings.TrimSpace(r.FormValue("username"))
	pw := r.FormValue("password")
	if !unameRe.MatchString(orig) {
		renderForm(w, "Name must be 3-20 characters: letters, numbers, _ or -.")
		return
	}
	if len(pw) < 4 || len(pw) > 100 {
		renderForm(w, "Password must be 4-100 characters.")
		return
	}
	unameKey := strings.ToLower(orig) // identity is case-insensitive; original case kept for display

	accMu.Lock()
	meta, exists := accounts.Users[unameKey]
	var key []byte
	var accountID int
	var display string
	if exists {
		salt, _ := hex.DecodeString(meta.Salt)
		key, _ = pbkdf2.Key(sha256.New, pw, salt, kdfIters, 32)
		if vdata, err := os.ReadFile(verifierPath(meta.ID)); err == nil {
			if _, err := decryptBytes(key, vdata); err != nil {
				accMu.Unlock()
				renderForm(w, "Wrong password for that name.")
				return
			}
		}
		accountID = meta.ID
		display = meta.Display
		if display == "" {
			display = unameKey // legacy account saved before display names existed
		}
	} else {
		salt := randBytes(16)
		key, _ = pbkdf2.Key(sha256.New, pw, salt, kdfIters, 32)
		if *adminUser != "" && unameKey == strings.ToLower(*adminUser) {
			accountID = 1
		} else {
			accountID = accounts.NextID
			accounts.NextID++
		}
		display = orig
		accounts.Users[unameKey] = accountMeta{ID: accountID, Salt: hex.EncodeToString(salt), Display: orig}
		if enc, err := encryptBytes(key, []byte(verifierConst)); err == nil {
			os.WriteFile(verifierPath(accountID), enc, 0o600)
		}
		saveAccounts()
		log.Printf("created account %q (id %d)", orig, accountID)
	}
	accMu.Unlock()

	sid := hex.EncodeToString(randBytes(32))
	s := &session{Username: display, AccountID: accountID, Key: key}
	sessMu.Lock()
	sessions[sid] = s
	sessByAcct[accountID] = s
	sessMu.Unlock()

	http.Redirect(w, r, "/finishAuth.html?authtoken="+sid, http.StatusFound)
}

func handleMatchmaker(w http.ResponseWriter, r *http.Request) {
	// Path: /matchmaker/queue/{server}/{queue}/{queueToken}/{accountToken}
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/matchmaker/queue/"), "/")
	queue := ""
	if len(parts) >= 2 {
		queue = parts[1]
	}
	queueToken := "" // present on zone transitions; signed by the game server
	if len(parts) >= 4 {
		queueToken = parts[2]
	}

	// Boss editor playtest: guest, a fresh ephemeral Arena each time. The boss being
	// authored is sent in the login frame, not the token. Arena isn't persisted, so no
	// session/password is needed.
	if queue == "Arena" {
		respondFound(w, map[string]any{
			"accountid": 2, "matchid": hex.EncodeToString(randBytes(8)), "levelToLoad": "Arena",
			"dungeonLevel": 0, "corruptionLevel": 0, "mutations": []string{},
			"screenname": "Editor", "returnWorldPos": []float64{0, 0},
		})
		return
	}

	// Everything else requires a logged-in session (account token = last path segment).
	sid := lastSegment(r.URL.Path)
	sessMu.Lock()
	s := sessions[sid]
	sessMu.Unlock()
	if s == nil {
		cors(w)
		io.WriteString(w, "invalidnonce")
		return
	}

	if queue == "World" {
		// Overworld. Returning from a zone carries a returnWorldPos in the queue token.
		var pos any = []float64{0, 0}
		if claims, err := decodeHS256(queueToken); err == nil && claims["returnWorldPos"] != nil {
			pos = claims["returnWorldPos"]
		}
		respondFound(w, map[string]any{
			"accountid": s.AccountID, "matchid": "1", "levelToLoad": "World",
			"dungeonLevel": 0, "corruptionLevel": 0, "mutations": []string{},
			"screenname": s.Username, "returnWorldPos": pos,
		})
		return
	}

	// Zone transition (dungeon, etc.): the destination is in the game-server-signed
	// queue token. Decode it and mint a match token for that zone.
	claims, err := decodeHS256(queueToken)
	if err != nil {
		cors(w)
		io.WriteString(w, "invalidqueuetoken")
		return
	}
	respondFound(w, map[string]any{
		"accountid":       s.AccountID,
		"matchid":         asMatchID(claims["matchId"]), // server requires matchid to be a string
		"levelToLoad":     claims["levelName"],
		"dungeonLevel":    orDefault(claims["dungeonLevel"], 0),
		"corruptionLevel": orDefault(claims["corruptionLevel"], 0),
		"mutations":       orDefault(claims["mutations"], []string{}),
		"screenname":      s.Username,
		"returnWorldPos":  orDefault(claims["returnWorldPos"], []float64{0, 0}),
	})
}

// respondFound stamps expiry/iat, signs the match JWT, and writes the matchmaker reply.
func respondFound(w http.ResponseWriter, claims map[string]any) {
	claims["expires"] = time.Now().UnixMilli() + 24*60*60*1000
	claims["iat"] = time.Now().Unix() - 300
	token, err := signHS256(claims)
	if err != nil {
		http.Error(w, "token signing failed", http.StatusInternalServerError)
		return
	}
	acct := "1"
	switch v := claims["accountid"].(type) {
	case int:
		acct = strconv.Itoa(v)
	case float64:
		acct = strconv.Itoa(int(v))
	}
	writeJSON(w, map[string]any{"status": "found", "serverAddress": "localhost-0", "token": token, "accountId": acct})
}

// decodeHS256 verifies an HS256 token with the shared secret and returns its claims.
func decodeHS256(token string) (map[string]any, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return nil, errors.New("malformed token")
	}
	mac := hmac.New(sha256.New, jwtSecret)
	mac.Write([]byte(parts[0] + "." + parts[1]))
	if !hmac.Equal([]byte(base64.RawURLEncoding.EncodeToString(mac.Sum(nil))), []byte(parts[2])) {
		return nil, errors.New("bad signature")
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, err
	}
	var claims map[string]any
	if err := json.Unmarshal(payload, &claims); err != nil {
		return nil, err
	}
	return claims, nil
}

// orDefault guards a passed-through claim so a missing/null value can't trip the
// server's required-field check.
func orDefault(v, def any) any {
	if v == nil {
		return def
	}
	return v
}

// asMatchID coerces a queue token's matchId to a string (the server requires the
// match token's "matchid" to be a string). JSON numbers decode to float64, so an
// integer matchId like 982212 must be formatted without a decimal point.
func asMatchID(v any) string {
	switch x := v.(type) {
	case string:
		return x
	case float64:
		return strconv.FormatFloat(x, 'f', -1, 64)
	default:
		return fmt.Sprintf("%v", x)
	}
}

// ---- persistence (encrypted with the session's password-derived key) ----

func handleSave(kind string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := lastSegment(r.URL.Path)
		acct, ok := accountIDFromPersistID(id)
		if !ok {
			http.Error(w, "bad id", http.StatusBadRequest)
			return
		}
		sessMu.Lock()
		s := sessByAcct[acct]
		sessMu.Unlock()
		if s == nil {
			// No active session => no key => refuse rather than write plaintext.
			http.Error(w, "no active session", http.StatusServiceUnavailable)
			return
		}
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "read error", http.StatusBadRequest)
			return
		}
		enc, err := encryptBytes(s.Key, body)
		if err != nil {
			http.Error(w, "encrypt error", http.StatusInternalServerError)
			return
		}
		if err := os.WriteFile(savePathEnc(kind, id), enc, 0o600); err != nil {
			http.Error(w, "write error", http.StatusInternalServerError)
			return
		}
		cors(w)
		io.WriteString(w, "ok")
	}
}

func handleFetch(kind string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		cors(w)
		id := lastSegment(r.URL.Path)
		acct, ok := accountIDFromPersistID(id)
		if !ok {
			io.WriteString(w, "null")
			return
		}
		sessMu.Lock()
		s := sessByAcct[acct]
		sessMu.Unlock()
		data, err := os.ReadFile(savePathEnc(kind, id))
		if err != nil || s == nil {
			io.WriteString(w, "null") // new character, or no session
			return
		}
		plain, err := decryptBytes(s.Key, data)
		if err != nil {
			log.Printf("WARN: could not decrypt %s for account %d", id, acct)
			io.WriteString(w, "null")
			return
		}
		w.Write(plain)
	}
}

func handleNoOp(w http.ResponseWriter, r *http.Request) {
	cors(w)
	io.WriteString(w, "ok")
}

// ---- crypto ----

func encryptBytes(key, plaintext []byte) ([]byte, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	nonce := randBytes(gcm.NonceSize())
	return gcm.Seal(nonce, nonce, plaintext, nil), nil
}

func decryptBytes(key, data []byte) ([]byte, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	if len(data) < gcm.NonceSize() {
		return nil, errors.New("ciphertext too short")
	}
	nonce, ct := data[:gcm.NonceSize()], data[gcm.NonceSize():]
	return gcm.Open(nil, nonce, ct, nil)
}

func signHS256(claims map[string]any) (string, error) {
	header := b64(`{"alg":"HS256","typ":"JWT"}`)
	payloadJSON, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}
	signingInput := header + "." + b64(string(payloadJSON))
	mac := hmac.New(sha256.New, jwtSecret)
	mac.Write([]byte(signingInput))
	return signingInput + "." + base64.RawURLEncoding.EncodeToString(mac.Sum(nil)), nil
}

func b64(s string) string { return base64.RawURLEncoding.EncodeToString([]byte(s)) }

func randBytes(n int) []byte {
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		log.Fatalf("crypto/rand failed: %v", err)
	}
	return b
}

// ---- secret + accounts persistence ----

func loadOrCreateSecret(path string) []byte {
	if b, err := os.ReadFile(path); err == nil {
		if s := strings.TrimSpace(string(b)); s != "" {
			return []byte(s)
		}
	}
	s := hex.EncodeToString(randBytes(32))
	if err := os.WriteFile(path, []byte(s), 0o600); err != nil {
		log.Printf("WARN: could not write secret file %q: %v (using built-in default)", path, err)
		return []byte(defaultSecret)
	}
	log.Printf("generated new per-host secret -> %s", path)
	return []byte(s)
}

func loadAccounts() {
	b, err := os.ReadFile(accountsPath())
	if err != nil {
		return // fresh install
	}
	var a accountsFile
	if err := json.Unmarshal(b, &a); err != nil {
		log.Printf("WARN: could not parse accounts.json: %v", err)
		return
	}
	if a.Users == nil {
		a.Users = map[string]accountMeta{}
	}
	if a.NextID < firstAccountID {
		a.NextID = firstAccountID
	}
	accounts = a
}

func saveAccounts() {
	b, _ := json.MarshalIndent(accounts, "", "  ")
	if err := os.WriteFile(accountsPath(), b, 0o644); err != nil {
		log.Printf("WARN: could not write accounts.json: %v", err)
	}
}

// ---- paths / helpers ----

func accountsPath() string         { return filepath.Join(*savesDir, "accounts.json") }
func verifierPath(id int) string   { return filepath.Join(*savesDir, "acct_"+strconv.Itoa(id)+".verifier") }
func savePathEnc(k, id string) string {
	return filepath.Join(*savesDir, k+"-"+sanitize(id)+".enc")
}

// accountIDFromPersistID pulls the trailing integer out of ids like "1",
// "playerinv_1", "playerbank_42" (characterId == accountId).
func accountIDFromPersistID(id string) (int, bool) {
	i := len(id)
	for i > 0 && id[i-1] >= '0' && id[i-1] <= '9' {
		i--
	}
	if i == len(id) {
		return 0, false
	}
	n, err := strconv.Atoi(id[i:])
	if err != nil {
		return 0, false
	}
	return n, true
}

func sanitize(s string) string {
	return strings.Map(func(r rune) rune {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '-', r == '_':
			return r
		default:
			return '_'
		}
	}, s)
}

func lastSegment(p string) string {
	p = strings.TrimRight(p, "/")
	if i := strings.LastIndex(p, "/"); i >= 0 {
		return p[i+1:]
	}
	return p
}

func writeJSON(w http.ResponseWriter, v any) {
	cors(w)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(v)
}

func cors(w http.ResponseWriter) { w.Header().Set("Access-Control-Allow-Origin", "*") }

func withLog(h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s", r.Method, r.URL.Path)
		h(w, r)
	}
}

func abs(p string) string {
	if a, err := filepath.Abs(p); err == nil {
		return a
	}
	return p
}

func portOnly(addr string) string {
	if i := strings.LastIndex(addr, ":"); i >= 0 {
		return addr[i:]
	}
	return addr
}

// renderForm writes the local login page shown in the popup.
func renderForm(w http.ResponseWriter, errMsg string) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	errBlock := ""
	if errMsg != "" {
		errBlock = `<p class="err">` + html.EscapeString(errMsg) + `</p>`
	}
	fmt.Fprintf(w, `<!doctype html><html><head><meta charset="utf-8"><title>Wyld Land — Login</title>
<style>
 body{background:#16131f;color:#eee;font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
 form{background:#221d30;padding:28px 30px;border-radius:10px;width:300px;box-shadow:0 8px 30px rgba(0,0,0,.5)}
 h1{font-size:20px;margin:0 0 4px}
 p.sub{color:#9c93b3;font-size:13px;margin:0 0 18px}
 label{display:block;font-size:13px;margin:12px 0 4px;color:#cfc6e0}
 input{width:100%%;box-sizing:border-box;padding:9px;border-radius:6px;border:1px solid #3a3350;background:#15121d;color:#fff;font-size:14px}
 button{width:100%%;margin-top:18px;padding:10px;border:0;border-radius:6px;background:#7c5cff;color:#fff;font-size:15px;cursor:pointer}
 button:hover{background:#8d6fff}
 p.note{color:#857a9c;font-size:11px;margin-top:16px;line-height:1.5}
 p.err{color:#ff7b7b;font-size:13px;margin:0 0 10px}
</style></head><body>
<form method="post" action="/auth/local/submit">
 <h1>Wyld Land</h1>
 <p class="sub">Enter a name to play. New name = new character.</p>
 %s
 <label for="u">Name</label>
 <input id="u" name="username" autofocus autocomplete="username" maxlength="20" placeholder="3-20 chars: letters, numbers, _ -">
 <label for="p">Password</label>
 <input id="p" name="password" type="password" autocomplete="current-password" maxlength="100">
 <button type="submit">Play</button>
 <p class="note">Your password encrypts your save. There is no recovery — if you
 forget it, that character is gone. Don't reuse an important password.</p>
</form></body></html>`, errBlock)
}
