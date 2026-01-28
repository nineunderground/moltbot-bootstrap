# Moltbot Bootstrap

One-command deployment for [Moltbot](https://github.com/moltbot/moltbot) — on bare metal or Docker.

## Docker Deployment (Recommended for NAS/Containers)

### Quick Start

```bash
# Clone
git clone https://github.com/nineunderground/moltbot-bootstrap.git
cd moltbot-bootstrap

# Configure
cp .env.example .env
nano .env  # Add your ANTHROPIC_API_KEY

# Build and run
docker-compose up -d
```

Your Moltbot is now running at `http://localhost:4001`

### With OAuth2 Proxy (GitHub Login)

To protect your Moltbot behind GitHub authentication:

```bash
# Configure (fill in GitHub OAuth + cookie secret)
cp .env.example .env
nano .env

# Build and run with oauth2 profile
docker-compose --profile oauth2 up -d
```

Your Moltbot is now at `http://localhost:4180` (behind GitHub login).

See [OAuth2 Proxy Setup](#oauth2-proxy-github-authentication) for full details.

### Docker Build & Run (Manual)

```bash
# Build the image
docker build -t moltbot-gateway .

# Run with environment variables
docker run -d \
  --name moltbot-gateway \
  -p 4001:4001 \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  -e CLAWDBOT_GATEWAY_PORT=4001 \
  -e TELEGRAM_BOT_TOKEN="123456789:ABC..." \
  -v clawdbot-data:/root/clawd \
  -v clawdbot-config:/root/.clawdbot \
  --restart unless-stopped \
  moltbot-gateway
```

### Custom Port

```bash
# Use port 5000 instead
docker run -d \
  --name moltbot-gateway \
  -p 5000:5000 \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  -e CLAWDBOT_GATEWAY_PORT=5000 \
  -v clawdbot-data:/root/clawd \
  -v clawdbot-config:/root/.clawdbot \
  moltbot-gateway
```

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | Yes | — | Your Anthropic API key |
| `CLAWDBOT_GATEWAY_PORT` | No | `4001` | Gateway port |
| `CLAWDBOT_GATEWAY_TOKEN` | No | auto-generated | Auth token for secure access |
| `TELEGRAM_BOT_TOKEN` | No | — | Telegram bot token from @BotFather |
| `CLAWDBOT_REGENERATE_CONFIG` | No | — | Set to `1` to regenerate config on restart |

### Persistent Data

The container uses two volumes:
- `clawdbot-data` → `/root/clawd` (workspace, memory, files)
- `clawdbot-config` → `/root/.clawdbot` (configuration, state)

### View Logs

```bash
docker logs -f moltbot-gateway
```

### First Run Token

On first run, if you don't provide `CLAWDBOT_GATEWAY_TOKEN`, one is auto-generated and printed to the logs:

```bash
docker logs moltbot-gateway | grep "GATEWAY TOKEN"
```

**Save this token!** You'll need it to access the gateway securely.

---

## OAuth2 Proxy (GitHub Authentication)

Protect your Moltbot Control UI behind GitHub login using [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/).

### Architecture

```
Internet → Reverse Proxy (SSL) → oauth2-proxy (:4180) → Moltbot (:4001)
                                  (GitHub OAuth)          (internal)
```

### Step 1: Create a GitHub OAuth App

1. Go to **https://github.com/settings/developers**
2. Click **"New OAuth App"**
3. Fill in:

| Field | Value |
|-------|-------|
| Application name | `Moltbot` |
| Homepage URL | `https://your-domain.com` |
| Authorization callback URL | `https://your-domain.com/oauth2/callback` |

4. Click **Register application**
5. Copy the **Client ID** and generate a **Client Secret**

### Step 2: Configure

Edit your `.env` file:

```bash
# GitHub OAuth App credentials
GITHUB_CLIENT_ID=your-client-id
GITHUB_CLIENT_SECRET=your-client-secret

# Generate cookie secret: openssl rand -hex 16
OAUTH2_COOKIE_SECRET=your-cookie-secret

# Redirect URL (must match GitHub OAuth App callback URL)
OAUTH2_REDIRECT_URL=https://your-domain.com/oauth2/callback

# GitHub username allowed to access
GITHUB_ALLOWED_USER=your-github-username
```

### Step 3: Run

```bash
# Start both Moltbot and oauth2-proxy
docker-compose --profile oauth2 up -d
```

### Step 4: Point your reverse proxy

Update your reverse proxy (FRP/nginx/Caddy) to forward traffic to **port 4180** (oauth2-proxy) instead of 4001:

```
your-domain.com → Reverse Proxy (SSL) → :4180 (oauth2-proxy) → :4001 (Moltbot)
```

### Access Restriction

By default, **any GitHub user can log in**. Restrict access using one or more of these options:

#### Option 1: Restrict by GitHub username (recommended)

In `.env`:
```bash
GITHUB_ALLOWED_USER=nineunderground
```

Multiple users (comma-separated):
```bash
GITHUB_ALLOWED_USER=nineunderground,another-user
```

#### Option 2: Restrict by GitHub organization

Only members of a specific GitHub org can access:
```bash
GITHUB_ALLOWED_ORG=your-org-name
```

#### Option 3: Restrict by GitHub org + team

Only members of a specific team within an org:
```bash
GITHUB_ALLOWED_ORG=your-org-name
GITHUB_ALLOWED_TEAM=your-team-name
```

#### Option 4: Restrict by email allowlist

Edit `allowed-emails.txt` with one email per line:
```
PUT-YOUR-EMAIL-HERE
```

The file is mounted automatically into the oauth2-proxy container.

> **Important:** Do NOT set `OAUTH2_PROXY_EMAIL_DOMAINS=*` — it overrides the email file and allows everyone.

> **Note:** You can combine options. For example, restrict by username AND email for double verification.

### OAuth2 Proxy Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GITHUB_CLIENT_ID` | Yes | — | GitHub OAuth App Client ID |
| `GITHUB_CLIENT_SECRET` | Yes | — | GitHub OAuth App Client Secret |
| `OAUTH2_COOKIE_SECRET` | Yes | — | Cookie encryption secret (`openssl rand -hex 16`) |
| `OAUTH2_REDIRECT_URL` | Yes | — | Must match GitHub callback URL |
| `GITHUB_ALLOWED_USER` | No | — | Restrict by GitHub username(s), comma-separated |
| `GITHUB_ALLOWED_ORG` | No | — | Restrict by GitHub organization |
| `GITHUB_ALLOWED_TEAM` | No | — | Restrict by GitHub team (requires org) |
| `OAUTH2_EMAILS_FILE` | No | — | Path to allowed emails file |
| `OAUTH2_PROXY_PORT` | No | `4180` | OAuth2 proxy port |

### Flow

1. User opens `https://your-domain.com`
2. oauth2-proxy redirects to GitHub login
3. GitHub authenticates → redirects back
4. oauth2-proxy verifies the GitHub username → forwards traffic to Moltbot
5. Moltbot gateway token is still required on first browser visit (`?token=...`)

### Troubleshooting

**404 after login:**
- Check oauth2-proxy can reach Moltbot: `docker logs moltbot-proxy`
- Both containers must be on the same Docker network (`moltbot-net`)

**WebSocket issues:**
- Ensure your reverse proxy passes `Upgrade` and `Connection` headers

**Wrong callback URL:**
- The `OAUTH2_REDIRECT_URL` must exactly match the callback URL in your GitHub OAuth App settings

---

## Bare Metal Deployment (VPS/Server)

### Quick Start

```bash
git clone https://github.com/nineunderground/moltbot-bootstrap.git
cd moltbot-bootstrap

# Create config
cp config.example.json config.json
nano config.json  # Edit with your values

# Deploy
sudo ./deploy.sh config.json
```

### Config File

```json
{
  "workspace": "/root/clawd",
  "gateway": {
    "port": 18181,
    "token": "your-secure-token"
  },
  "telegram": {
    "botToken": "from-botfather"
  },
  "anthropic": {
    "apiKey": "sk-ant-..."
  }
}
```

### What It Does

1. ✅ Installs Node.js 22 (if needed)
2. ✅ Installs Moltbot globally via official installer
3. ✅ Creates workspace directory
4. ✅ Generates Moltbot config from your JSON
5. ✅ Sets up systemd service with auto-restart
6. ✅ Starts the gateway

---

## Management Commands

### Docker

```bash
# Status
docker ps | grep moltbot

# Logs
docker logs -f moltbot-gateway

# Restart
docker restart moltbot-gateway

# Stop
docker stop moltbot-gateway

# Shell into container
docker exec -it moltbot-gateway bash

# Run clawdbot CLI inside container
docker exec moltbot-gateway clawdbot status
docker exec moltbot-gateway clawdbot pairing list telegram
```

### Bare Metal (systemd)

```bash
clawdbot status
journalctl -u moltbot-gateway -f
systemctl restart moltbot-gateway
```

---

## Telegram Pairing

After deployment, DM your Telegram bot. You'll receive a pairing code.

**Docker:**
```bash
docker exec moltbot-gateway clawdbot pairing list telegram
docker exec moltbot-gateway clawdbot pairing approve telegram <CODE>
```

**Bare metal:**
```bash
clawdbot pairing list telegram
clawdbot pairing approve telegram <CODE>
```

---

## Security

- Always set `CLAWDBOT_GATEWAY_TOKEN` before exposing to the internet
- Use OAuth2 proxy for web UI access control (see above)
- Use [moltbot-nginx-proxy-docker](https://github.com/nineunderground/moltbot-nginx-proxy-docker) for HTTPS
- Keep your API keys and tokens secure

---

## Related

- [Moltbot](https://github.com/moltbot/moltbot) — The AI assistant platform
- [moltbot-nginx-proxy-docker](https://github.com/nineunderground/moltbot-nginx-proxy-docker) — HTTPS reverse proxy
- [Moltbot Docs](https://docs.molt.bot) — Official documentation

## License

MIT
