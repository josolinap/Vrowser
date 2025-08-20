# ---------- Build stage ----------
FROM node:18-bookworm-slim AS base

# Install only what Chrome needs (and nothing more)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg \
    # Chrome runtime deps
    fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 \
    libcups2 libdbus-1-3 libdrm2 libgtk-3-0 libnspr4 libnss3 libx11-6 \
    libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 libgbm1 \
    xdg-utils \
  && rm -rf /var/lib/apt/lists/*

# Add Google Chrome repo & install stable
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
    gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] \
    https://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# ---------- Runtime stage ----------
FROM base AS runtime

WORKDIR /usr/src/app

# Create low-privilege user (never run as root)
RUN groupadd -r pptruser && useradd -r -g pptruser pptruser

# Copy dependency list and install
COPY package*.json ./
RUN npm ci --omit=dev

# Copy application code
COPY . .

# Ensure the user owns the workdir
RUN chown -R pptruser:pptruser /usr/src/app

USER pptruser

# Health-check for Render / k8s
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD curl -f http://localhost:${PORT:-10000}/health || exit 1

EXPOSE 10000
ENV PORT=10000
CMD ["node", "server.js"]
