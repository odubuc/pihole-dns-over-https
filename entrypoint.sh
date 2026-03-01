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

# Set listening mode to 'all' by default so Pi-hole accepts queries regardless of
# network topology (Docker bridge, host, cloud). Users can override this at runtime
# with -e FTLCONF_dns_listeningMode=local (or single).
if [ -z "$FTLCONF_dns_listeningMode" ]; then
    echo "[pihole-dns-over-https] Setting dns.listeningMode=all (override with FTLCONF_dns_listeningMode env var)"
    pihole-FTL --config dns.listeningMode all 2>/dev/null || true
fi

# Hand off to the original Pi-hole entrypoint
exec start.sh
