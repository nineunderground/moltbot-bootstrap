# Clawdbot Bootstrap

One-command deployment for Clawdbot on a fresh VPS.

## Quick Start

```bash
# 1. Create your config
cp config.example.json config.json
nano config.json  # Edit with your values

# 2. Deploy
sudo ./deploy.sh config.json
```

That's it! Clawdbot will be running as a systemd service.

## Config File

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

| Field | Required | Description |
|-------|----------|-------------|
| `workspace` | No | Agent workspace directory (default: `/root/clawd`) |
| `gateway.port` | No | Gateway port (default: `18181`) |
| `gateway.token` | Yes | Auth token for secure access |
| `telegram.botToken` | No | Telegram bot token from @BotFather |
| `anthropic.apiKey` | Yes | Your Anthropic API key |

## What It Does

1. ✅ Installs Node.js 22 (if needed)
2. ✅ Installs Clawdbot globally via npm
3. ✅ Creates workspace directory
4. ✅ Generates Clawdbot config from your JSON
5. ✅ Sets up environment variables securely
6. ✅ Creates systemd service with auto-restart
7. ✅ Starts the gateway

## Management

```bash
# Check status
clawdbot status

# View logs
journalctl -u clawdbot-gateway -f

# Restart
systemctl restart clawdbot-gateway

# Stop
systemctl stop clawdbot-gateway

# Check pending Telegram pairings
clawdbot pairing list telegram

# Approve a pairing
clawdbot pairing approve telegram <CODE>
```

## Multiple Instances

To run multiple Clawdbot instances on the same server:

1. Use different config files with unique ports
2. The script creates `clawdbot-gateway.service` — rename for additional instances

```bash
# Instance 1 (port 18181)
./deploy.sh config-prod.json

# Instance 2 (port 18182) — manually adjust service name
./deploy.sh config-dev.json
# Then: mv /etc/systemd/system/clawdbot-gateway.service /etc/systemd/system/clawdbot-dev.service
```

## Security Notes

- Environment file (`/etc/clawdbot.env`) has restricted permissions (600)
- Always set a strong `gateway.token` before exposing to the internet
- Use the [nginx proxy](https://github.com/nineunderground/clawdbot-nginx-proxy-docker) for HTTPS

## Requirements

- Ubuntu/Debian Linux (other distros need minor adjustments)
- Root access
- `jq` or `python3` for JSON parsing (optional, script handles both)
