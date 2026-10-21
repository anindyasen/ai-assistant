# Prerequisites

Manual, one-time steps you must complete. These are browser logins, exports, and personal paths that OpenCode cannot do for you.

Setup checks, package installs, model pulls, and config linking are handled by `scripts/setup/` — run those yourself or ask OpenCode to run them.

---

## 1. Obsidian vault

If you already have a vault, note its absolute path (e.g. `~/Obsidian/Vault`).

If not, create one:

```bash
mkdir -p ~/Obsidian/Vault/"Daily Notes"
```

Tell OpenCode the path on first use, or add to your shell profile:

```bash
export OBSIDIAN_VAULT=~/Obsidian/Vault
```

---

## 2. Notion integration (~5 min)

1. Go to <https://www.notion.so/my-integrations>
2. **New integration** → name it (e.g. "Local AI") → pick your workspace
3. Copy the **Internal Integration Secret** (`secret_...`)
4. Open each Notion page you want AI access to → `...` menu → **Connections** → add your integration
5. Create the env file:

```bash
mkdir -p ~/.config/local-ai
cp config/mcp/notion.env.example ~/.config/local-ai/notion.env
# edit ~/.config/local-ai/notion.env and paste your secret
```

---

## 3. Gmail + Google Drive (~20 min)

1. Go to <https://console.cloud.google.com/>
2. **Create project** (e.g. "local-ai")
3. **APIs & Services → Library** → enable **Gmail API**
   - Optional: also enable **Google Drive API** if you want Docs/Drive access
4. **APIs & Services → OAuth consent screen**
   - User type: **External**
   - Add yourself as a **Test user** (your Gmail address)
   - Scopes: `gmail.readonly`, `gmail.modify`, `gmail.compose` (+ `drive.file` if using Drive)
5. **APIs & Services → Credentials → Create Credentials → OAuth client ID**
   - Application type: **Desktop app**
   - Download the JSON and save as:

```bash
mkdir -p ~/.config/local-ai/gmail
# save the downloaded file as:
~/.config/local-ai/gmail/credentials.json
```

The first Gmail request will open a browser for consent; a token is then cached alongside the credentials.

---

## 4. Portfolio CSV (~10 min)

Export your holdings from your Indian broker (Zerodha / Groww / ICICI / etc.) and save as:

```
~/Finance/portfolio.csv
```

Expected header + format:

```csv
symbol,qty,avg_price
RELIANCE,10,2850.50
HDFCBANK,25,1640.00
INFY,15,1520.75
```

If your export uses different column names, note them — the script can be adjusted.

---

## 5. (Optional) Mobile / LAN access

Decide how your phone will reach the assistant:

- **Tailscale** (recommended) — private mesh VPN, no port-forwarding
- **LAN-only** — same Wi-Fi network, no remote access
- **Reverse proxy** — advanced, needs a domain + TLS

This affects Phase 8 setup only; nothing to do now unless you already know your choice.

---

## Checklist

| # | Step | Done |
|---|------|------|
| 1 | Obsidian vault path known | ☐ |
| 2 | Notion API key in `~/.config/local-ai/notion.env` | ☐ |
| 3 | Gmail credentials at `~/.config/local-ai/gmail/credentials.json` | ☐ |
| 4 | Portfolio CSV at `~/Finance/portfolio.csv` | ☐ |
| 5 | (Optional) Mobile/LAN decision | ☐ |
