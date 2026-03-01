FROM pihole/pihole:latest

LABEL maintainer="Olivier Dubuc"
LABEL url="https://github.com/odubuc/pihole-dns-over-https"

# dnscrypt-proxy version
ARG DNSCRYPT_PROXY_VERSION=2.1.15

# Cloudflare DNS variant: cloudflare, cloudflare-security, cloudflare-family
ARG DNSCRYPT_SERVER_NAMES=cloudflare

# Download and install dnscrypt-proxy binary
# The Pi-hole image is Alpine-based, so we download the static Linux binary
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64)  DNSCRYPT_ARCH="linux_x86_64" ;; \
        aarch64) DNSCRYPT_ARCH="linux_arm64" ;; \
        armv7l)  DNSCRYPT_ARCH="linux_arm" ;; \
        armv6l)  DNSCRYPT_ARCH="linux_arm" ;; \
        i386)    DNSCRYPT_ARCH="linux_i386" ;; \
        *)       echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    wget -q "https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${DNSCRYPT_PROXY_VERSION}/dnscrypt-proxy-${DNSCRYPT_ARCH}-${DNSCRYPT_PROXY_VERSION}.tar.gz" -O /tmp/dnscrypt-proxy.tar.gz && \
    tar xzf /tmp/dnscrypt-proxy.tar.gz -C /tmp && \
    mv /tmp/linux-*/dnscrypt-proxy /usr/local/bin/dnscrypt-proxy && \
    chmod +x /usr/local/bin/dnscrypt-proxy && \
    rm -rf /tmp/dnscrypt-proxy.tar.gz /tmp/linux-*

# Create config directory and add dnscrypt-proxy configuration
RUN mkdir -p /etc/dnscrypt-proxy /var/cache/dnscrypt-proxy
COPY dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
RUN sed -i "s/server_names = .*/server_names = ['${DNSCRYPT_SERVER_NAMES}']/" /etc/dnscrypt-proxy/dnscrypt-proxy.toml

# Copy custom entrypoint that starts dnscrypt-proxy before Pi-hole
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

