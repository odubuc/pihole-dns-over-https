# pihole-dns-over-https

Pi-hole Docker image with built-in DNS-over-HTTPS (DoH) via [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy).

All DNS queries between Pi-hole and upstream servers are encrypted, preventing man-in-the-middle attacks.

Based on the official [Pi-hole documentation](https://docs.pi-hole.net/guides/dns/dnscrypt-proxy/).

## Image Tags

| Tag | Upstream DNS | Description |
|---|---|---|
| `latest` | Cloudflare (`1.1.1.1`) | Standard DNS resolution |
| `security` | Cloudflare Security | Blocks malware and phishing |
| `family` | Cloudflare Family | Blocks malware, phishing, and adult content |

Each tag is also available with a version suffix (e.g., `1.0.0`, `security-1.0.0`, `family-1.0.0`).

## Quick Start

```bash
docker run -d \
  --name pihole-dns-over-https \
  -p 53:53/tcp \
  -p 53:53/udp \
  -p 80:80 \
  -e TZ=America/Toronto \
  -e FTLCONF_webserver_api_password=your-password \
  odubuc/pihole-dns-over-https:latest
```

For malware-blocking DNS:

```bash
docker run -d \
  --name pihole-dns-over-https \
  -p 53:53/tcp \
  -p 53:53/udp \
  -p 80:80 \
  -e TZ=America/Toronto \
  -e FTLCONF_webserver_api_password=your-password \
  odubuc/pihole-dns-over-https:security
```

## Docker Compose

```yaml
services:
  pihole:
    image: odubuc/pihole-dns-over-https:latest
    container_name: pihole-dns-over-https
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80"
    environment:
      TZ: America/Toronto
      FTLCONF_webserver_api_password: your-password
    volumes:
      - pihole_data:/etc/pihole
      - dnsmasq_data:/etc/dnsmasq.d
    restart: unless-stopped

volumes:
  pihole_data:
  dnsmasq_data:
```

## How It Works

1. Pi-hole receives DNS queries on port 53
2. Pi-hole forwards queries to dnscrypt-proxy on `127.0.0.1:5053`
3. dnscrypt-proxy encrypts and sends queries to Cloudflare via DNS-over-HTTPS
4. Responses travel back through the same encrypted path

## Multi-Architecture Support

Images are built for:
- `linux/amd64` (x86_64)
- `linux/arm64` (Raspberry Pi 4/5, Apple Silicon)
- `linux/arm/v7` (Raspberry Pi 3)

## Building Locally

```bash
# Default (Cloudflare standard)
docker build -t pihole-dns-over-https .

# With a specific variant
docker build --build-arg DNSCRYPT_SERVER_NAMES=cloudflare-security -t pihole-dns-over-https:security .
docker build --build-arg DNSCRYPT_SERVER_NAMES=cloudflare-family -t pihole-dns-over-https:family .
```

## License

[MIT](LICENCE)
