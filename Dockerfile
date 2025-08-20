# ---------- Base ----------
FROM node:18-bookworm-slim AS base

# minimal runtime deps for Chrome
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg fonts-liberation libasound2 libatk-bridge2.0-0 \
    libatk1.0-0 libatspi2.0-0 libcups2 libdbus-1-3 libdrm2 libgtk-3-0 \
    libnspr4 libnss3 libx11-6 libxcomposite1 libxdamage1 libxext6 \
    libxfixes3 libxrandr2 libgbm1 xdg-utils \
  && rm -rf /var/lib/apt/lists/*

# Google Chrome repo + install
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
    gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] \
    https://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# ---------- Runtime ----------
FROM base AS runtime
WORKDIR /usr/src/app

# create user AND its home directory
RUN groupadd -r pptruser && useradd -r -g pptruser -d /home/pptruser -s /bin/bash pptruser \
 && mkdir -p /home/pptruser/Downloads \
 && chown -R pptruser:pptruser /home/pptruser

COPY package.json ./
RUN yarn install --production

COPY . .
RUN chown -R pptruser:pptruser /usr/src/app
USER pptruser

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD node -e "require('http').get('http://localhost:${PORT:-10000}/health', r => r.statusCode === 200 ? process.exit(0) : process.exit(1))"
EXPOSE 10000
ENV PORT=10000
CMD ["node", "server.js"]
