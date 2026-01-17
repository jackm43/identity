# Ory Kratos Specification

## Overview

Self-hosted Ory Kratos for identity management, providing authentication flows (registration, login, recovery) with GitHub OAuth integration.

## Components

### kratos.yml (Main Config)
- DSN connection to PostgreSQL
- Self-service flow URLs (login, registration, recovery, settings)
- Session cookie configuration
- OIDC provider configuration

### identity.schema.json
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "traits": {
      "type": "object",
      "properties": {
        "email": { "type": "string", "format": "email" },
        "name": { "type": "string" }
      },
      "required": ["email"]
    }
  }
}
```

### GitHub OIDC Provider
- Provider ID: `github`
- Callback URL: `https://kratos.jsmunro.me/self-service/methods/oidc/callback/github`
- Scopes: `user:email`

### Self-Service UI
- `kratos-selfservice-ui-node` for login/registration pages
- Proxies to Kratos public API

## Database

PostgreSQL with DSN: `postgres://kratos:${POSTGRES_PASSWORD}@postgres:5432/kratos?sslmode=disable`

## Configuration Requirements

| Item | Location | Notes |
|------|----------|-------|
| kratos.yml | `kratos/` in git | Main config |
| identity.schema.json | `kratos/` in git | Identity traits |
| github_mapper.jsonnet | `kratos/` in git | OIDC claims mapper |
| Secrets | `.env` (not in git) | `POSTGRES_PASSWORD`, GitHub OAuth credentials |

### Required Settings
- `dsn`: PostgreSQL connection string
- `serve.public.base_url`: `https://kratos.jsmunro.me`
- `serve.admin.base_url`: `http://kratos:4434` (internal)
- `session.cookie.domain`: `jsmunro.me`

## GitHub OAuth

### Callback URL
`https://kratos.jsmunro.me/self-service/methods/oidc/callback/github`

### Scopes
- `user:email` (required)

### Jsonnet Mapper (github_mapper.jsonnet)
```jsonnet
local claims = std.extVar('claims');
{
  identity: {
    traits: {
      email: claims.email,
      name: claims.name,
    },
  },
}
```

## Acceptance Criteria

- [ ] Kratos starts with valid config (`kratos serve` exits 0)
- [ ] Registration flow creates identity with email/name traits
- [ ] Login flow authenticates existing identity
- [ ] GitHub sign-in redirects, authenticates, and creates/links identity
- [ ] Identity for `jack@jsmunro.me` can be created via registration or GitHub
