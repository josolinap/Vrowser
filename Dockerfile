# ---------- Stage 1: build static webvnc ----------
FROM alpine:3.20 AS builder
RUN apk add --no-cache \
      build-base git cmake \
      libx11-dev libxfixes-dev libjpeg-turbo-dev \
      openssl-dev
# (openssl-dev is needed even though we disable TLS in cmake)

WORKDIR /src
RUN git clone --depth=1 https://github.com/LibVNC/libvncserver.git
WORKDIR /src/libvncserver
RUN mkdir build && cd build \
  && cmake .. \
     -DCMAKE_BUILD_TYPE=MinSizeRel \
     -DWITH_GNUTLS=OFF \
     -DWITH_OPENSSL=OFF \
     -DBUILD_SHARED_LIBS=OFF \
  && make -j$(nproc) \
  && strip examples/webvncserver/webvncserver \
  && mv examples/webvncserver/webvncserver /usr/local/bin/webvnc

# ---------- Stage 2: runtime ----------
FROM alpine:3.20
RUN apk add --no-cache \
      xvfb xauth xsetroot \
      chromium \
      dumb-init \
      su-exec
RUN adduser -D -s /bin/sh browser
COPY --from=builder /usr/local/bin/webvnc /usr/local/bin/webvnc
COPY start.sh /start.sh
RUN chmod +x /start.sh
EXPOSE 8080
ENTRYPOINT ["dumb-init", "--"]
CMD ["/start.sh"]
