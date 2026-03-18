#!/usr/bin/env bash
set -euo pipefail

# WildDex Backend - M1 MacBook Air Deployment Setup
# Run this script on the M1 MBA to set up auto-start + Cloudflare Tunnel.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_SRC="$SCRIPT_DIR/com.wilddex.backend.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.wilddex.backend.plist"

echo "=== WildDex Backend Deployment Setup ==="
echo ""

# Step 1: Install launchd service
echo "1. Installing launchd service..."
if [ -f "$PLIST_DEST" ]; then
    echo "   Unloading existing service..."
    launchctl bootout "gui/$(id -u)/com.wilddex.backend" 2>/dev/null || true
fi
cp "$PLIST_SRC" "$PLIST_DEST"
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
echo "   Done. Service installed and started."

# Step 2: Health check cron
echo ""
echo "2. Setting up health check cron (every 5 minutes)..."
CRON_LINE="*/5 * * * * $SCRIPT_DIR/health_check.sh"
(crontab -l 2>/dev/null | grep -v "health_check.sh"; echo "$CRON_LINE") | crontab -
echo "   Done."

# Step 3: Cloudflare Tunnel
echo ""
echo "3. Cloudflare Tunnel setup..."
if command -v cloudflared &>/dev/null; then
    echo "   cloudflared is already installed."
else
    echo "   Installing cloudflared via Homebrew..."
    brew install cloudflared
fi
echo ""
echo "   To create a quick tunnel (no account needed), run:"
echo "     cloudflared tunnel --url http://localhost:8000"
echo ""
echo "   This gives you a temporary *.trycloudflare.com URL."
echo "   For a persistent tunnel with custom domain, run:"
echo "     cloudflared tunnel login"
echo "     cloudflared tunnel create wilddex"
echo "     cloudflared tunnel route dns wilddex api.yourdomain.com"
echo "     cloudflared tunnel run --url http://localhost:8000 wilddex"

# Step 4: Verify
echo ""
echo "4. Verifying backend is running..."
sleep 3
if curl -s --max-time 5 http://localhost:8000/health | grep -q '"ok"'; then
    echo "   Backend is healthy!"
else
    echo "   Backend may still be loading the model. Check logs:"
    echo "     tail -f $SCRIPT_DIR/server.log"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Start Cloudflare Tunnel: cloudflared tunnel --url http://localhost:8000"
echo "  2. Copy the public URL and update wilddex/lib/constants.dart"
echo "  3. Set CORS_ORIGINS env var in the plist to your tunnel domain"
echo "  4. Rebuild Flutter app: cd wilddex && flutter build apk --release"
echo "  5. For web: cd wilddex && flutter build web --release"
