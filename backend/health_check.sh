#!/usr/bin/env bash
# Health check script for WildDex backend.
# Add to crontab: */5 * * * * /Users/zain/Developer/wilddex/backend/health_check.sh

HEALTH_URL="http://localhost:8000/health"
SERVICE_LABEL="com.wilddex.backend"
LOG_FILE="/Users/zain/Developer/wilddex/backend/health_check.log"

response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$HEALTH_URL" 2>/dev/null)

if [ "$response" != "200" ]; then
    echo "$(date): Health check failed (HTTP $response). Restarting..." >> "$LOG_FILE"
    launchctl kickstart -k "gui/$(id -u)/$SERVICE_LABEL" 2>> "$LOG_FILE"
else
    echo "$(date): OK" >> "$LOG_FILE"
fi
