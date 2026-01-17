#!/bin/bash
set -euo pipefail

KRATOS_ADMIN_URL="${KRATOS_ADMIN_URL:-http://localhost:4434}"
EMAIL="jack@jsmunro.me"

echo "Checking if identity exists for ${EMAIL}..."

RESPONSE=$(curl -s -w "\n%{http_code}" "${KRATOS_ADMIN_URL}/admin/identities?credentials_identifier=${EMAIL}")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
    echo "Error: Failed to query identities (HTTP ${HTTP_CODE})"
    exit 1
fi

IDENTITY_COUNT=$(echo "$BODY" | jq 'length')

if [ "$IDENTITY_COUNT" -gt 0 ]; then
    IDENTITY_ID=$(echo "$BODY" | jq -r '.[0].id')
    echo "Identity already exists: ${IDENTITY_ID}"
    exit 0
fi

echo "Creating identity for ${EMAIL}..."

CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${KRATOS_ADMIN_URL}/admin/identities" \
    -H "Content-Type: application/json" \
    -d '{
        "schema_id": "default",
        "traits": {
            "email": "'"${EMAIL}"'",
            "name": {
                "first": "Jack",
                "last": "Munro"
            }
        },
        "verifiable_addresses": [
            {
                "value": "'"${EMAIL}"'",
                "verified": true,
                "via": "email",
                "status": "completed"
            }
        ]
    }')

CREATE_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
CREATE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')

if [ "$CREATE_CODE" = "201" ]; then
    IDENTITY_ID=$(echo "$CREATE_BODY" | jq -r '.id')
    echo "Identity created: ${IDENTITY_ID}"
    exit 0
else
    echo "Error: Failed to create identity (HTTP ${CREATE_CODE})"
    echo "$CREATE_BODY" | jq . 2>/dev/null || echo "$CREATE_BODY"
    exit 1
fi
