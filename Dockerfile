# ---------- Base ----------
FROM node:18-alpine AS base

# Install chromium and the tiny tools we need for swap
RUN apk add --no-cache \
      chromium \
      nss \
      freetype \
      harfbuzz \
      ca-certificates \
      ttf-freefont \
      util-linux

# ---------- Runtime ----------
FROM base AS runtime
WORKDIR /usr/src/app

# Create a low-privilege user
RUN addgroup -S pptruser && \
    adduser -S -G pptruser -h /home/pptruser pptruser && \
    mkdir -p /home/pptruser/Downloads && \
    chown -R pptruser:pptruser /home/pptruser

# Add 512 MB swap inside the container
RUN dd if=/dev/zero of=/swapfile bs=1M count=512 && \
    chmod 600 /swapfile && \
    mkswap /swapfile

# Enable swap at runtime via a simple startup script
RUN mkdir -p /usr/local/bin && \
    printf '#!/bin/sh\n/sbin/swapon /swapfile\nexec "$@"\n' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Copy package files and install only production deps
COPY package.json ./
RUN yarn install --production && yarn cache clean

# Copy source and fix permissions
COPY . .
RUN chown -R pptruser:pptruser /usr/src/app
USER pptruser

# Puppeteer will find chromium here
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser \
    NODE_OPTIONS="--max-old-space-size=256"

# Tiny health-check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD node -e "require('http').get('http://localhost:${PORT:-10000}/health', r => r.statusCode === 200 ? process.exit(0) : process.exit(1))"

EXPOSE 10000
ENV PORT=10000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["node", "server.js"]
