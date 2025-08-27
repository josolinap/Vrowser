FROM alpine:3.20

# runtime packages only
RUN apk add --no-cache \
      xvfb xauth xsetroot \
      chromium \
      x11vnc \
      py3-websockify \
      dumb-init \
      su-exec

# lightweight user
RUN adduser -D -s /bin/sh browser

# startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080
ENTRYPOINT ["dumb-init", "--"]
CMD ["/start.sh"]
