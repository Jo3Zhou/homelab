#!/usr/bin/env bash
set -euo pipefail

# Install Tailscale
if command -v tailscale &>/dev/null; then
    echo "Tailscale already installed: $(tailscale version)"
else
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# Authenticate and bring up
echo "Starting Tailscale (browser login may be required)..."
sudo tailscale up

# Expose port 80 publicly via Tailscale Funnel (Jellyfin only)
echo "Enabling Tailscale Funnel on port 80 (public)..."
sudo tailscale funnel --bg 80

# Expose port 8888 to Tailnet only via Tailscale Serve (all services)
echo "Enabling Tailscale Serve on port 8888 (Tailnet only)..."
sudo tailscale serve --bg 8888

echo ""
echo "Public access (Jellyfin only):"
tailscale funnel status 2>/dev/null | grep https || true
echo ""
echo "Internal access (all services):"
tailscale serve status 2>/dev/null | grep http || true
