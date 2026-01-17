# Implementation Plan

## Goal
Self-hosted Ory Kratos IAM on AWS EC2 with GitHub OIDC, Cloudflare Tunnel, and homelab authentication.

---

## Phase 1: Foundation

### 1.1 Repository Structure [DONE]
**Spec:** N/A (scaffolding)

- [x] Create directory structure:
  - `infra/terraform/` - AWS infrastructure
  - `deploy/` - Docker Compose files
  - `kratos/` - Kratos config + identity schema
  - `scripts/` - Utility scripts (seed identity, etc.)
- [x] Create `.env.example` with required variables
- [x] Create `.gitignore` (exclude .env, *.pem, tunnel credentials)

**Tests:**
- `terraform fmt -check` passes
- `docker compose config` validates

---

### 1.2 AWS Infrastructure via Terraform [DONE]
**Spec:** [specs/infrastructure.md](specs/infrastructure.md)

- [x] Terraform provider with AWS profile `terraform`
- [x] VPC/Security Group (SSH from admin IP, egress all)
- [x] EC2 instance (Ubuntu LTS, t3.small)
- [x] Use keypair "Github and SSH Key"
- [x] Output instance public IP
- [x] User data script: install Docker + docker compose

**Tests:**
- `terraform plan` clean
- `terraform apply` succeeds
- SSH: `ssh -i "GitHub and SSH Key.pem" ubuntu@<ip>` works
- `docker --version` returns valid version

---

## Phase 2: Kratos Core

### 2.1 Docker Compose Setup [DONE]
**Spec:** [specs/kratos.md](specs/kratos.md)

- [x] `deploy/docker-compose.yml` with services:
  - `postgres` (PostgreSQL 15, persistent volume)
  - `kratos-migrate` (one-shot migration job)
  - `kratos` (public:4433, admin:4434 internal only)
  - `kratos-ui` (self-service UI on port 4455)
- [x] `.env` with: `POSTGRES_PASSWORD`, `KRATOS_ADMIN_SECRET`, `KRATOS_SECRETS_COOKIE`, `KRATOS_SECRETS_CIPHER`
- [x] Volumes for Postgres data and Kratos config

**Tests:**
- `docker compose up -d` all containers healthy
- `curl localhost:4433/health/ready` returns 200
- Postgres persists data across restarts

---

### 2.2 Kratos Configuration [DONE]
**Spec:** [specs/kratos.md](specs/kratos.md)

- [x] `kratos/kratos.yml`:
  - DSN: `postgres://kratos:${POSTGRES_PASSWORD}@postgres:5432/kratos?sslmode=disable`
  - `serve.public.base_url`: `https://auth.jsmunro.me`
  - `serve.admin.base_url`: `http://kratos:4434` (internal)
  - Self-service flow URLs (login, registration, settings, recovery, verification)
  - Session cookie settings (domain: `.jsmunro.me`, secure: true)
  - CORS for UI origin
- [x] `kratos/identity.schema.json`:
  - Email trait (identifier, verification, recovery)
  - Name traits (first, last)

**Tests:**
- Kratos starts without config errors
- `GET /self-service/registration/browser` returns flow
- Schema validation: invalid traits rejected

---

### 2.3 GitHub OIDC Provider [PARTIAL - Manual Steps Remaining]
**Spec:** [specs/kratos.md](specs/kratos.md)

**Code Configuration (DONE):**
- [x] Add to `kratos.yml` oidc providers:
  - provider: github
  - client_id/client_secret (from .env)
  - scopes: [user:email]
  - mapper_url (base64 Jsonnet for email mapping)
- [x] `kratos/oidc/github_mapper.jsonnet` - map email_primary to traits.email

**Manual Steps (NOT STARTED):**
- [ ] Create GitHub OAuth App:
  - Homepage: `https://auth.jsmunro.me`
  - Callback: `https://auth.jsmunro.me/self-service/methods/oidc/callback/github`
- [ ] Add GitHub OAuth credentials to `.env` (GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET)

**Tests:**
- Login page shows "Sign in with GitHub"
- Complete OAuth flow → session created
- Identity created with email from GitHub

---

## Phase 3: Networking & Security

### 3.1 Cloudflare Tunnel [PARTIAL - Manual Steps Remaining]
**Spec:** [specs/networking.md](specs/networking.md)

**Infrastructure Configuration (DONE):**
- [x] Add `cloudflared` service to docker-compose.yml
- [x] `cloudflared/config.yml`:
  - Ingress: `auth.jsmunro.me` → `http://kratos:4433`
  - Ingress: `login.jsmunro.me` → `http://kratos-ui:4455`
  - Default: 404

**Manual Steps (NOT STARTED):**
- [ ] Create Cloudflare Tunnel via dashboard or CLI
- [ ] Store tunnel credentials at `/opt/identity/cloudflared/`
- [ ] DNS CNAME records in Cloudflare

**Tests:**
- `cloudflared tunnel info` shows healthy
- `curl -I https://auth.jsmunro.me/health/ready` returns 200
- Admin API NOT accessible via tunnel

---

### 3.2 TLS Configuration [NOT STARTED]
**Spec:** [specs/networking.md](specs/networking.md)

- [ ] Cloudflare SSL mode: Full (strict) if using origin cert, else Full
- [ ] Verify automatic edge certificates for jsmunro.me
- [ ] (Optional) Cloudflare Origin CA cert for origin-to-edge encryption

**Tests:**
- Browser shows valid certificate for auth.jsmunro.me
- `curl -Iv https://auth.jsmunro.me` shows correct cert chain
- No mixed content warnings

---

## Phase 4: Identity & Integration

### 4.1 Seed Identity [PARTIAL - Manual Steps Remaining]
**Spec:** [specs/kratos.md](specs/kratos.md)

**Script (DONE):**
- [x] `scripts/seed_identity.sh`:
  - Create identity for jack@jsmunro.me via Admin API
  - Set email as verified
  - Idempotent (skip if exists)

**Manual Steps (NOT STARTED):**
- [ ] Document Admin API access (SSH tunnel or local only)

**Tests:**
- Run script → identity created
- Run script again → no error, no duplicate
- `GET /admin/identities` shows jack@jsmunro.me

---

### 4.2 Homelab Auth Gateway [FUTURE]
**Spec:** [specs/networking.md](specs/networking.md)

- [ ] Add Ory Oathkeeper to protect homelab services
- [ ] Configure access rules (authenticate via Kratos session)
- [ ] Cloudflared tunnel from homelab to EC2 (or vice versa)
- [ ] Route protected services through Oathkeeper

**Tests:**
- Unauthenticated request → redirect to login
- Authenticated request → access granted
- Logout → access revoked

---

## Dependency Graph

```
1.1 Repo Structure
    ↓
1.2 AWS Infrastructure
    ↓
2.1 Docker Compose → 2.2 Kratos Config → 2.3 GitHub OIDC
                ↓
            3.1 Cloudflare Tunnel → 3.2 TLS
                        ↓
                    4.1 Seed Identity
                        ↓
                    4.2 Homelab Auth (future)
```

---

## Files to Create

| Path | Purpose |
|------|---------|
| `infra/terraform/main.tf` | EC2 + security group |
| `infra/terraform/variables.tf` | Input variables |
| `infra/terraform/outputs.tf` | Instance IP output |
| `deploy/docker-compose.yml` | All services |
| `deploy/.env.example` | Template for secrets |
| `kratos/kratos.yml` | Kratos configuration |
| `kratos/identity.schema.json` | Identity schema |
| `kratos/oidc/github.jsonnet` | GitHub claim mapper |
| `cloudflared/config.yml` | Tunnel ingress rules |
| `scripts/seed_identity.sh` | Create jack@jsmunro.me |

---

## Notes

- **Secrets:** Never commit .env, tunnel credentials, or .pem files
- **Admin API:** Bind to localhost/docker network only, never expose publicly
- **Cookie domain:** Use `.jsmunro.me` for cross-subdomain auth
- **Oathkeeper:** Required for protecting non-Kratos services (Phase 4.2)
- **Manual Configuration Required:** GitHub OIDC (2.3) and Cloudflare Tunnel (3.1) require manual steps that cannot be automated (OAuth app creation in GitHub, tunnel creation via Cloudflare dashboard/CLI)
