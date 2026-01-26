# Clawdbot Bootstrap

One-command deployment for [Clawdbot](https://github.com/clawdbot/clawdbot) — on bare metal or Docker.

## Docker Deployment (Recommended for NAS/Containers)

### Quick Start

```bash
# Clone
git clone https://github.com/nineunderground/clawdbot-bootstrap.git
cd clawdbot-bootstrap

# Configure
cp .env.example .env
nano .env  # Add your ANTHROPIC_API_KEY

# Build and run
docker compose up -d
```

Your Clawdbot is now running at `http://localhost:4001`

### Docker Build & Run (Manual)

```bash
# Build the image
docker build -t clawdbot .

# Run with environment variables
docker run -d \
  --name clawdbot-gateway \
  -p 4001:4001 \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  -e CLAWDBOT_GATEWAY_PORT=4001 \
  -e TELEGRAM_BOT_TOKEN="123456789:ABC..." \
  -v clawdbot-data:/root/clawd \
  -v clawdbot-config:/root/.clawdbot \
  --restart unless-stopped \
  clawdbot
```

### Custom Port

```bash
# Use port 5000 instead
docker run -d \
  --name clawdbot-gateway \
  -p 5000:5000 \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  -e CLAWDBOT_GATEWAY_PORT=5000 \
  -v clawdbot-data:/root/clawd \
  -v clawdbot-config:/root/.clawdbot \
  clawdbot
```

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | Yes | — | Your Anthropic API key |
| `CLAWDBOT_GATEWAY_PORT` | No | `4001` | Gateway port |
| `CLAWDBOT_GATEWAY_TOKEN` | No | auto-generated | Auth token for secure access |
| `TELEGRAM_BOT_TOKEN` | No | — | Telegram bot token from @BotFather |
| `CLAWDBOT_REGENERATE_CONFIG` | No | — | Set to `1` to regenerate config on restart |

### Docker Compose

```yaml
version: '3.8'
services:
  clawdbot:
    build: .
    ports:
      - "4001:4001"
    environment:
      - ANTHROPIC_API_KEY=sk-ant-...
      - TELEGRAM_BOT_TOKEN=123456789:ABC...
    volumes:
      - clawdbot-data:/root/clawd
      - clawdbot-config:/root/.clawdbot
    restart: unless-stopped

volumes:
  clawdbot-data:
  clawdbot-config:
```

### Persistent Data

The container uses two volumes:
- `clawdbot-data` → `/root/clawd` (workspace, memory, files)
- `clawdbot-config` → `/root/.clawdbot` (configuration, state)

### View Logs

```bash
docker logs -f clawdbot-gateway
```

### First Run Token

On first run, if you don't provide `CLAWDBOT_GATEWAY_TOKEN`, one is auto-generated and printed to the logs:

```bash
docker logs clawdbot-gateway | grep "GATEWAY TOKEN"
```

**Save this token!** You'll need it to access the gateway securely.

---

## Bare Metal Deployment (VPS/Server)

### Quick Start

```bash
git clone https://github.com/nineunderground/clawdbot-bootstrap.git
cd clawdbot-bootstrap

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
2. ✅ Installs Clawdbot globally via npm
3. ✅ Creates workspace directory
4. ✅ Generates Clawdbot config from your JSON
5. ✅ Sets up systemd service with auto-restart
6. ✅ Starts the gateway

---

## Management Commands

### Docker

```bash
# Status
docker ps | grep clawdbot

# Logs
docker logs -f clawdbot-gateway

# Restart
docker restart clawdbot-gateway

# Stop
docker stop clawdbot-gateway

# Shell into container
docker exec -it clawdbot-gateway bash

# Run clawdbot CLI inside container
docker exec clawdbot-gateway clawdbot status
docker exec clawdbot-gateway clawdbot pairing list telegram
```

### Bare Metal (systemd)

```bash
clawdbot status
journalctl -u clawdbot-gateway -f
systemctl restart clawdbot-gateway
```

---

## Telegram Pairing

After deployment, DM your Telegram bot. You'll receive a pairing code.

**Docker:**
```bash
docker exec clawdbot-gateway clawdbot pairing list telegram
docker exec clawdbot-gateway clawdbot pairing approve telegram <CODE>
```

**Bare metal:**
```bash
clawdbot pairing list telegram
clawdbot pairing approve telegram <CODE>
```

---

## Security

- Always set `CLAWDBOT_GATEWAY_TOKEN` before exposing to the internet
- Use [clawdbot-nginx-proxy-docker](https://github.com/nineunderground/clawdbot-nginx-proxy-docker) for HTTPS
- Keep your API keys and tokens secure

---

## Related

- [Clawdbot](https://github.com/clawdbot/clawdbot) — The AI assistant platform
- [clawdbot-nginx-proxy-docker](https://github.com/nineunderground/clawdbot-nginx-proxy-docker) — HTTPS reverse proxy
- [Clawdbot Docs](https://docs.clawd.bot) — Official documentation

## License

MIT
