# ---------- Stage 1: build tiny static VNC server ----------
FROM alpine:3.20 AS build
RUN apk add --no-cache build-base git cmake libx11-dev libxfixes-dev libjpeg-turbo-dev \
 && git clone --depth=1 https://github.com/novnc/websockify /src/websockify \
 && git clone --depth=1 https://github.com/LibVNC/libvncserver /src/libvncserver \
 && cd /src/libvncserver && mkdir build && cd build \
 && cmake .. -DCMAKE_BUILD_TYPE=MinSizeRel -DWITH_GNUTLS=OFF -DWITH_OPENSSL=OFF \
 && make -j$(nproc) \
 && strip examples/webvncserver/webvncserver \
 && mv examples/webvncserver/webvncserver /usr/local/bin/webvnc

# ---------- Stage 2: runtime image ----------
FROM alpine:3.20

# minimal runtime deps
RUN apk add --no-cache \
      xvfb xauth xsetroot \
      chromium \
      dumb-init \
      su-exec

# lightweight user
RUN adduser -D -s /bin/sh browser

# copy static webvnc binary
COPY --from=build /usr/local/bin/webvnc /usr/local/bin/webvnc

# startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080
ENTRYPOINT ["dumb-init", "--"]
CMD ["/start.sh"]
