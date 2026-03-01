#!/bin/bash
set -e

# Start dnscrypt-proxy in the background
echo "[pihole-dns-over-https] Starting dnscrypt-proxy..."
/usr/local/bin/dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml &

# Wait for dnscrypt-proxy to be ready (up to 30 seconds)
echo "[pihole-dns-over-https] Waiting for dnscrypt-proxy to be ready..."
RETRIES=0
MAX_RETRIES=30
while [ "$RETRIES" -lt "$MAX_RETRIES" ]; do
    if dig +short +timeout=1 +retry=0 @127.0.0.1 -p 5053 cloudflare.com > /dev/null 2>&1; then
        echo "[pihole-dns-over-https] dnscrypt-proxy is ready."
        break
    fi
    RETRIES=$((RETRIES + 1))
    sleep 1
done

if [ "$RETRIES" -ge "$MAX_RETRIES" ]; then
    echo "[pihole-dns-over-https] WARNING: dnscrypt-proxy did not become ready within ${MAX_RETRIES}s. Continuing anyway..."
fi

# Configure Pi-hole to use dnscrypt-proxy as upstream DNS on port 5053
echo "[pihole-dns-over-https] Configuring Pi-hole upstream DNS to use dnscrypt-proxy (127.0.0.1#5053)..."
pihole-FTL --config dns.upstreams '["127.0.0.1#5053"]' 2>/dev/null || true

# Hand off to the original Pi-hole entrypoint
exec start.sh
