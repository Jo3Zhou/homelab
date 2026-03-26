# Homelab

Self-hosted media and file server running on Docker, exposed via Tailscale.

## Services

| Service | URL | Description |
|---------|-----|-------------|
| [Homepage](https://gethomepage.dev) | `/` | Dashboard |
| [Jellyfin](https://jellyfin.org) | `/jellyfin` | Media server |
| [Radarr](https://radarr.video) | `/radarr` | Movie collection manager |
| [Filebrowser](https://filebrowser.xyz) | `/files` | File manager |
| [Pingvin Share](https://pingvin-share.dev.eliasschneider.com) | `/share` | File sharing with expiry |
| [Caddy](https://caddyserver.com) | — | Reverse proxy |
| [Tailscale](https://tailscale.com) | — | Remote access (runs on host) |

## Requirements

- Docker + Docker Compose
- Linux host with Intel GPU (for Jellyfin hardware transcoding)
- Tailscale account

## Setup

**1. Clone the repo**
```bash
git clone <repo-url>
cd homelab
```

**2. Run the setup script**
```bash
./setup.sh
```

This creates the required host directories (`/srv/media`, `/srv/downloads`).

**3. Start all services**
```bash
docker compose up -d
```

**4. First-run configuration**

Jellyfin:
- Open `http://localhost/jellyfin` and complete the setup wizard
- Go to Admin > Dashboard > Advanced > Base URL → set to `/jellyfin` and restart
- Go to Admin > API Keys → create a key and paste it into `homepage/services.yaml`
- Add a media library pointing to `/media/Movies`

Radarr:
- Open `http://localhost/radarr` and complete the setup wizard
- Go to Settings > General > URL Base → set to `/radarr`
- Go to Settings > General > API Key → copy and paste it into `homepage/services.yaml`
- Add a root folder pointing to `/movies`

Filebrowser:
- Open `http://localhost/files`
- Default login: `admin` / `admin` — **change this immediately**

Pingvin Share:
- Open `http://localhost/share`
- Complete the setup wizard to create an admin account

**5. Set up Tailscale (remote access)**
```bash
./setup-tailscale.sh
```

This installs Tailscale, authenticates, and exposes port 80 via Tailscale Funnel so your homelab is reachable from anywhere.

## Adding media

Drop files into `/srv/media` on the host — Jellyfin will pick them up automatically.

```
/srv/media/
  Movies/       # Radarr and Jellyfin
```

## Configuration

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Service definitions |
| `Caddyfile` | Reverse proxy routing |
| `homepage/services.yaml` | Dashboard service links and widgets |
| `homepage/settings.yaml` | Dashboard appearance |
| `.env` | Optional path overrides (copy from `.env.example`) |

## Updating

```bash
docker compose pull
docker compose up -d
```

## Stopping

```bash
docker compose down        # stop services, keep data
docker compose down -v     # stop services and delete volumes (destructive)
```
