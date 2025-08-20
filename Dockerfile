# Use a slim Node.js base image to keep the image size minimal.
FROM node:18-slim

# Set the working directory inside the container.
WORKDIR /usr/src/app

# Install system dependencies for a headless browser (Google Chrome).
# These are essential for Chrome to run correctly.
# The --no-install-recommends flag helps reduce image size further.
RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    libnss3 \
    libxss1 \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libcurl4 \
    libgtk-3-0 \
    libx11-xcb1 \
    libxcb-dri3-0 \
    lsb-release \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Add Google Chrome's official signing key.
RUN curl -sSLo - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg

# Add the Google Chrome repository to your sources list.
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list

# Update and install Google Chrome Stable.
# This step installs the browser itself, which `puppeteer-core` will control.
RUN apt-get update && \
    apt-get install -y google-chrome-stable

# Copy package.json and install dependencies.
# Using `puppeteer-core` instead of `puppeteer` is key for a lightweight build
# because it doesn't download the browser, which we've already installed.
COPY package.json ./
RUN npm install

# Copy the rest of your application code into the container.
COPY . .

# Expose the port your web server or API will listen on.
EXPOSE 10000

# Define the command to start your application.
CMD ["npm", "start"]
