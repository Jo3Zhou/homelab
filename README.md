# Homelab

Self-hosted services running on Docker, exposed publicly via Cloudflare Tunnel and privately via Tailscale.

## Services

| Service | Public URL | Description |
|---------|-----------|-------------|
| Jellyfin | `jellyfin.yourdomain.com` | Media server |
| Immich | `photos.yourdomain.com` | Photo backup |
| Nextcloud | `cloud.yourdomain.com` | File storage |
| Vaultwarden | `vault.yourdomain.com` | Password manager |
| Grafana | `grafana.yourdomain.com` (Tailscale only) | Monitoring |

## Architecture

```
Internet ──► Cloudflare Edge ──► cloudflared ──► Caddy ──► services
Tailscale ──────────────────────────────────────► Caddy ──► services
```

Caddy handles routing and TLS (via Cloudflare DNS-01 challenge). Cloudflare Tunnel handles public exposure without opening any ports on your router.

---

## Setup

### 1. Prerequisites

- Docker + Docker Compose installed on the host
- NAS mounted at `/mnt/nas/` (or adjust paths in compose files)
- A domain managed by Cloudflare
- A Cloudflare account with Zero Trust enabled (free tier is fine)

### 2. Clone and deploy files

```bash
git clone <repo-url>
cd homelab
```

Copy each section from `docker-compose.yml` into its corresponding file on the server at `/opt/homelab/`. The directory structure should be:

```
/opt/homelab/
├── .env
├── caddy/
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── Caddyfile
│   └── data/             ← create empty, gitignored
├── cloudflared/
│   └── docker-compose.yml
├── jellyfin/
│   └── docker-compose.yml
├── immich/
│   ├── docker-compose.yml
│   └── .env
├── nextcloud/
│   ├── docker-compose.yml
│   └── .env
├── vaultwarden/
│   └── docker-compose.yml
├── monitoring/
│   ├── docker-compose.yml
│   └── prometheus/
│       └── prometheus.yml
└── scripts/
    ├── start-all.sh
    └── backup-dbs.sh
```

### 3. Create the shared Docker network

```bash
docker network create proxy
```

### 4. Mount NAS directories

```bash
mkdir -p /mnt/nas/{media,photos,documents,backups/databases}
# then add NAS entries to /etc/fstab and run:
mount -a
```

### 5. Get a Cloudflare API token

1. Go to [Cloudflare dashboard](https://dash.cloudflare.com) → My Profile → API Tokens → Create Token
2. Use the **Edit zone DNS** template
3. Scope it to your domain
4. Copy the token — you'll use it as `CF_API_TOKEN`

### 6. Create a Cloudflare Tunnel

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com) → Networks → Tunnels → Create a tunnel
2. Name it (e.g. `homelab`), select **Docker**, copy the token — you'll use it as `CF_TUNNEL_TOKEN`
3. Under the tunnel's **Public Hostnames** tab, add one row per service:

   | Subdomain | Domain | Service URL |
   |-----------|--------|-------------|
   | `jellyfin` | `yourdomain.com` | `http://jellyfin:8096` |
   | `photos` | `yourdomain.com` | `http://immich-server:2283` |
   | `cloud` | `yourdomain.com` | `http://nextcloud:80` |
   | `vault` | `yourdomain.com` | `http://vaultwarden:80` |

   Leave Grafana out — it stays Tailscale-only.

### 7. Create secret files

**`/opt/homelab/.env`** (never commit this):
```bash
CF_API_TOKEN=your_cloudflare_api_token
CF_TUNNEL_TOKEN=your_cloudflare_tunnel_token
DOMAIN=yourdomain.com
ACME_EMAIL=you@email.com
```

**`/opt/homelab/immich/.env`**:
```bash
DB_HOSTNAME=immich-postgres
DB_USERNAME=immich
DB_PASSWORD=change_me
DB_DATABASE_NAME=immich
REDIS_HOSTNAME=immich-redis
```

**`/opt/homelab/nextcloud/.env`**:
```bash
MYSQL_HOST=nextcloud-db
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
MYSQL_PASSWORD=change_me
MYSQL_ROOT_PASSWORD=change_me_root
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=change_me
REDIS_HOST=nextcloud-redis
```

### 8. Start all services

Caddy must start first so the `proxy` network is populated before other services connect.

```bash
cd /opt/homelab
chmod +x scripts/start-all.sh
./scripts/start-all.sh
```

Or start manually in order:

```bash
docker compose -f caddy/docker-compose.yml build
docker compose -f caddy/docker-compose.yml up -d
docker compose -f cloudflared/docker-compose.yml up -d
docker compose -f jellyfin/docker-compose.yml up -d
docker compose -f immich/docker-compose.yml up -d
docker compose -f nextcloud/docker-compose.yml up -d
docker compose -f vaultwarden/docker-compose.yml up -d
docker compose -f monitoring/docker-compose.yml up -d
```

Verify everything is up:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---

## First-run configuration

### Jellyfin
- Open `https://jellyfin.yourdomain.com` and complete the setup wizard
- Add a media library pointing to `/media`

### Immich
- Open `https://photos.yourdomain.com` and create an admin account

### Nextcloud
- Open `https://cloud.yourdomain.com` — credentials are from `nextcloud/.env`
- Go to Settings → Security and set the trusted domain to `cloud.yourdomain.com`

### Vaultwarden
- Open `https://vault.yourdomain.com` → Create Account
- After creating your account, set `SIGNUPS_ALLOWED=false` in the compose file and restart:
  ```bash
  docker compose -f vaultwarden/docker-compose.yml up -d
  ```

### Grafana
- Open `https://grafana.yourdomain.com` (Tailscale required)
- Login: `admin` / the password in `GF_SECURITY_ADMIN_PASSWORD`
- Change the password immediately
- Add Prometheus as a datasource: `http://prometheus:9090`

---

## Maintenance

### Update all services
```bash
cd /opt/homelab
for dir in caddy jellyfin immich nextcloud vaultwarden monitoring cloudflared; do
  docker compose -f $dir/docker-compose.yml pull
  docker compose -f $dir/docker-compose.yml up -d
done
```

### Update Caddy (rebuild with latest plugin)
```bash
docker compose -f caddy/docker-compose.yml build --no-cache
docker compose -f caddy/docker-compose.yml up -d
```

### Database backups
Run manually or let the cron job handle it (runs nightly at 3am):
```bash
/opt/homelab/scripts/backup-dbs.sh
```

To install the cron job:
```bash
echo "0 3 * * * root /opt/homelab/scripts/backup-dbs.sh >> /var/log/homelab-backup.log 2>&1" \
  | sudo tee /etc/cron.d/homelab
```

### Stop everything
```bash
for dir in caddy jellyfin immich nextcloud vaultwarden monitoring cloudflared; do
  docker compose -f /opt/homelab/$dir/docker-compose.yml down
done
```
