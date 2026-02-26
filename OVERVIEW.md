# bootstrap

A collection of shell scripts for provisioning and managing Ubuntu/Debian VPS servers running Node.js apps behind Caddy.

---

## Install

Clone the repo on any machine (local or server) and run:

```bash
./init
source ~/.bashrc   # or ~/.zshrc
```

`init` symlinks every script in `bin/` into `~/bin/` and ensures `~/bin` is on `$PATH`. Scripts are invoked directly by name from any directory.

---

## Server layout

```
/etc/caddy/
  Caddyfile                  # global config — imports sites-enabled/*
  caddy-security.env         # JWT signing key (root:caddy 640, read by systemd)
  users.json                 # caddy-security identity store (caddy:caddy 600)
  sites-enabled/
    auth.trilbysir.com.conf  # login portal site
    app.trilbysir.com.conf   # example protected site
    pub.trilbysir.com.conf   # example public site

/etc/systemd/system/caddy.service.d/
  caddy-security.conf        # drop-in that passes CADDY_JWT_KEY env var to caddy

~/.ssh/
  deploy-keys/
    keys/                    # per-repo ed25519 keys
    config.d/                # per-repo SSH Host blocks
    meta/                    # metadata files (repo→key mapping)
  config                     # includes deploy-keys/config.d/*.conf
```

---

## Script reference

### Machine setup

| Script              | Purpose                                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------------------------- |
| `bootstrap-machine` | Base VPS setup: SSH structure, git defaults, base apt packages, docker group. Run once on a fresh server. |
| `bootstrap-dev`     | Dev toolchain: NVM, Node, pnpm, build tools. Pass `--docker` to also install Docker + buildx.             |
| `bootstrap-swap`    | Creates a swap file if none exists (defaults to 1G).                                                      |

### Caddy

| Script                     | Purpose                                                                                                                                                                         |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `bootstrap-caddy`          | Installs stock Caddy via apt, creates `sites-enabled/` structure, enables systemd service. Run before `bootstrap-caddy-security`.                                               |
| `bootstrap-caddy-security` | Builds Caddy with `caddy-security` plugin via xcaddy, generates JWT key, writes global Caddyfile with auth portal, creates `auth.<domain>` site. Run once per VPS.              |
| `review-caddy`             | Prints Caddy status, auth portal state, all site configs with auth method (public / basic auth / portal auth), duplicate check, and validation. Pass `-v` for full config dump. |

### Site management

| Script                                  | Purpose                                                                                                             |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `bind-domain-public <domain> <port>`    | Creates a public site config with security headers + reverse proxy.                                                 |
| `bind-domain-protected <domain> <port>` | Creates a site config protected by the caddy-security portal (`authorize with caddy-policy`).                       |
| `protect-domain <domain>`               | Migrates an existing site to portal auth — strips any `basic_auth` block and injects `authorize with caddy-policy`. |
| `lock-domain <domain>`                  | Locks DNS / additional hardening (see script).                                                                      |
| `open-domain <domain>`                  | Reverses lock-domain.                                                                                               |

### Auth portal user management

| Script            | Purpose                                                                                                                                                                    |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `add-portal-user` | Interactive: creates a user in `/etc/caddy/users.json` with bcrypt-hashed password. Prompts for username, email, password, and whether to grant admin role. Reloads Caddy. |

### Deploy keys

| Script                             | Purpose                                                                                    |
| ---------------------------------- | ------------------------------------------------------------------------------------------ |
| `bootstrap-repo <alias> <git-url>` | Generates an ed25519 deploy key, adds SSH Host config, prints public key to add to GitHub. |
| `list-deploy-keys`                 | Lists all managed deploy keys and their linked repos.                                      |
| `remove-deploy-key <alias>`        | Removes key, SSH config, and metadata for a repo.                                          |

### PM2 / Node

| Script               | Purpose                                                                |
| -------------------- | ---------------------------------------------------------------------- |
| `deploy-pnpm-script` | Pulls latest code, runs pnpm install + build, restarts PM2 process.    |
| `pm2-auto-update`    | Cron-friendly wrapper around deploy-pnpm-script for automated deploys. |
| `tune-pm2-logrotate` | Configures pm2-logrotate with sane defaults.                           |

### Diagnostics

| Script          | Purpose                                                                              |
| --------------- | ------------------------------------------------------------------------------------ |
| `server-doctor` | Health check: disk, memory, swap, PM2 processes, Caddy status, deploy key inventory. |

---

## Caddy auth architecture

All sites on the VPS share a single login session using `caddy-security` (cookie-based portal auth).

```
browser → app.trilbysir.com
            │
            ▼
         Caddy: authorize with caddy-policy
            │  no valid JWT cookie
            ▼
         redirect → auth.trilbysir.com
            │
            ▼
         login form (caddy-security portal)
            │  success
            ▼
         JWT cookie set on .trilbysir.com (24h)
            │
            ▼
         redirect back → app.trilbysir.com
            │  cookie present, policy passes
            ▼
         reverse_proxy → 127.0.0.1:PORT
```

**Key files:**

- `/etc/caddy/Caddyfile` — defines `security {}` block with identity store, portal, and policy. Rewritten by `bootstrap-caddy-security`.
- `/etc/caddy/caddy-security.env` — contains `CADDY_JWT_KEY=<hex>`. Permissions: `root:caddy 640`. Read by systemd before caddy starts.
- `/etc/caddy/users.json` — live user database managed by caddy-security. Permissions: `caddy:caddy 600`. Must be writable by the caddy process.

**Registration is disabled.** `/register*` routes return 403 at the Caddy level. New users are added exclusively via `add-portal-user` (runs as root on the server).

---

## Typical new server workflow

```bash
# 1. Clone and install scripts
git clone https://github.com/garciacsci/bootstrap ~/bootstrap
cd ~/bootstrap && ./init && source ~/.bashrc

# 2. Base provisioning
bootstrap-machine
bootstrap-dev
bootstrap-swap

# 3. Caddy + auth portal (takes ~2min to build xcaddy)
bootstrap-caddy
bootstrap-caddy-security trilbysir.com garciacsci@gmail.com

# 4. Create admin user
add-portal-user

# 5. Add sites
bind-domain-public  neighbors.trilbysir.com  3000
bind-domain-protected  app.trilbysir.com  3001

# 6. Verify
review-caddy
```

---

## Common issues

**Caddy fails to start with `permission denied` on `users.json`**
caddy-security writes to this file as a live database.

```bash
sudo chown caddy:caddy /etc/caddy/users.json
sudo chmod 600 /etc/caddy/users.json
sudo systemctl restart caddy
```

**Caddy fails to start with `permission denied` on `caddy-security.env`**

```bash
sudo chown root:caddy /etc/caddy/caddy-security.env
sudo chmod 640 /etc/caddy/caddy-security.env
sudo systemctl restart caddy
```

**Let's Encrypt rejects email**
`bootstrap-caddy-security` now prompts for email. If the Caddyfile has `you@example.com`:

```bash
sudo sed -i 's/email you@example.com/email real@email.com/' /etc/caddy/Caddyfile
sudo systemctl restart caddy
```

**caddy-security auto-created a `webadmin` account**
This happens when `users.json` is empty `{}` on first start. Remove it:

```bash
sudo python3 -c "
import json
with open('/etc/caddy/users.json') as f: d = json.load(f)
d.pop('webadmin', None)
with open('/etc/caddy/users.json', 'w') as f: json.dump(d, f, indent=2)
"
sudo systemctl reload caddy
```
