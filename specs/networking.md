# Networking Specification

## Overview

Cloudflare Tunnel provides secure, zero-trust access to services without exposing ports. DNS for jsmunro.me is managed via Cloudflare.

## Components

| Component | Purpose |
|-----------|---------|
| Cloudflare Tunnel (cloudflared) | Encrypted outbound connection to Cloudflare edge |
| DNS Records | `auth.jsmunro.me` CNAME → tunnel UUID |
| TLS | Cloudflare edge terminates TLS (Full mode) |

## Tunnel Configuration

### Docker Container

```yaml
cloudflared:
  image: cloudflare/cloudflared:latest
  command: tunnel run
  environment:
    - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
  restart: unless-stopped
```

### Ingress Rules

```yaml
ingress:
  - hostname: auth.jsmunro.me
    service: http://kratos:4433
  - service: http_status:404
```

### Security

- Admin API (port 4434) is NOT exposed via tunnel
- Only public endpoints accessible externally

## Homelab Integration

- Cloudflared can bridge EC2 and homelab services over the same tunnel
- Future: Ory Oathkeeper as auth gateway for protected services
- Tunnel originates outbound—no inbound firewall rules needed

## Acceptance Criteria

- [ ] `https://auth.jsmunro.me` reaches Kratos public API
- [ ] Valid TLS certificate (Cloudflare-issued)
- [ ] Admin API only accessible via localhost/internal network
- [ ] Tunnel maintains persistent connection
