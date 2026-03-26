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

# Expose port 80 via Tailscale Funnel so your homelab is reachable remotely
echo "Enabling Tailscale Funnel on port 80..."
sudo tailscale funnel --bg 80

echo ""
echo "Done. Your homelab is accessible at:"
tailscale funnel status 2>/dev/null | grep https || true
