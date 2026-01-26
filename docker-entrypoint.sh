#!/bin/bash
set -e

CONFIG_DIR="/root/.clawdbot"
CONFIG_FILE="$CONFIG_DIR/clawdbot.json"
WORKSPACE="/root/clawd"

# Ensure directories exist
mkdir -p "$CONFIG_DIR" "$WORKSPACE/memory"

# Generate config if it doesn't exist or if env vars are set
if [ ! -f "$CONFIG_FILE" ] || [ -n "$CLAWDBOT_REGENERATE_CONFIG" ]; then
    echo "Generating Clawdbot configuration..."
    
    # Use provided token or generate one
    GATEWAY_TOKEN="${CLAWDBOT_GATEWAY_TOKEN:-$(openssl rand -hex 32)}"
    
    # Build config
    cat > "$CONFIG_FILE" << EOF
{
  "agents": {
    "defaults": {
      "workspace": "$WORKSPACE",
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      },
      "compaction": {
        "mode": "safeguard"
      }
    }
  },
  "gateway": {
    "port": ${CLAWDBOT_GATEWAY_PORT:-4001},
    "mode": "local",
    "bind": "0.0.0.0",
    "auth": {
      "mode": "token",
      "token": "$GATEWAY_TOKEN"
    }
  },
  "channels": {
    "telegram": {
      "enabled": ${TELEGRAM_BOT_TOKEN:+true}${TELEGRAM_BOT_TOKEN:-false},
      "botToken": "${TELEGRAM_BOT_TOKEN:-}",
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  },
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": ${TELEGRAM_BOT_TOKEN:+true}${TELEGRAM_BOT_TOKEN:-false}
      }
    }
  },
  "messages": {
    "ackReactionScope": "group-mentions"
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  }
}
EOF

    echo "Config generated at $CONFIG_FILE"
    
    # Show token if it was auto-generated
    if [ -z "$CLAWDBOT_GATEWAY_TOKEN" ]; then
        echo ""
        echo "============================================"
        echo "AUTO-GENERATED GATEWAY TOKEN (save this!):"
        echo "$GATEWAY_TOKEN"
        echo "============================================"
        echo ""
    fi
fi

# If a custom config is mounted, use it
if [ -f "/config/clawdbot.json" ]; then
    echo "Using mounted config from /config/clawdbot.json"
    cp /config/clawdbot.json "$CONFIG_FILE"
fi

# Show startup info
echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║         Clawdbot Docker Container         ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
echo "  Port:      ${CLAWDBOT_GATEWAY_PORT:-4001}"
echo "  Workspace: $WORKSPACE"
echo "  Config:    $CONFIG_FILE"
echo "  Telegram:  ${TELEGRAM_BOT_TOKEN:+enabled}${TELEGRAM_BOT_TOKEN:-disabled}"
echo ""

# Execute the command
exec "$@"
