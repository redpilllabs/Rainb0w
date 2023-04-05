# syntax=docker/dockerfile:1.3
FROM caddy:builder-alpine AS builder
ENV CGO_ENABLED=0
ENV GOARCH=amd64
ENV GOOS=linux
RUN xcaddy build \
    --with github.com/mholt/caddy-l4 \
    --with github.com/mholt/caddy-dynamicdns \
    --with github.com/mholt/caddy-ratelimit \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mastercactapus/caddy2-proxyprotocol \
    --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive \
    --output ./caddy


FROM caddy:alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
RUN chmod +x /usr/bin/caddy
RUN apk add --no-cache bash \
    coreutils ca-certificates \
    nss nss-tools
RUN update-ca-certificates
ENTRYPOINT [ "caddy", "run", "--config", "/etc/caddy/caddy.json" ]
