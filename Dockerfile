FROM alpine:3.20

# 1. runtime packages only (no compilation)
RUN apk add --no-cache \
      xvfb xauth xsetroot \
      chromium \
      x11vnc \
      websockify \
      dumb-init \
      su-exec

# 2. non-root user
RUN adduser -D -s /bin/sh browser

# 3. tiny startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080
ENTRYPOINT ["dumb-init", "--"]
CMD ["/start.sh"]
