#!/usr/bin/env bash
set -euo pipefail

# Create host directories
echo "Creating directories..."
sudo mkdir -p /srv/media/Movies
sudo mkdir -p /srv/downloads
sudo chown -R "$USER:$USER" /srv/media /srv/downloads

echo ""
echo "Done. Next steps:"
echo "  1. Run: docker compose up -d"
echo "  2. Open Jellyfin at http://localhost/jellyfin and complete setup"
echo "     - Admin > Dashboard > Advanced > Base URL > set to /jellyfin"
echo "     - Admin > API Keys > create a key and add to homepage/services.yaml"
echo "  3. Open Radarr at http://localhost/radarr and complete setup"
echo "     - Settings > General > URL Base > set to /radarr"
echo "     - Settings > General > API Key > copy and add to homepage/services.yaml"
echo "  4. Open Filebrowser at http://localhost/files (default login: admin / admin — change it!)"
echo "  5. Open Pingvin Share at http://localhost/share"
echo "  6. Run ./setup-tailscale.sh to expose your homelab remotely"
