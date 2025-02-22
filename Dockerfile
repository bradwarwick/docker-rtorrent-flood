FROM alpine:3.15

ARG RTORRENT_VER=0.9.8
ARG LIBTORRENT_VER=0.13.8
ARG FLOOD_VER=4.7.0
ARG BUILD_CORES

ENV UID=991 GID=991 \
    FLOOD_SECRET=supersecret30charactersminimum \
    WEBROOT=/ \
    DISABLE_AUTH=false \
    RTORRENT_SOCK=true \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    GLOBAL_THROTTLE_RATE_DOWN=0 \
    GLOBAL_THROTTLE_RATE_UP=0

RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \
 && echo "@3.14 https://nl.alpinelinux.org/alpine/v3.14/main" >> /etc/apk/repositories \
 && apk -U upgrade \
 && apk add -t build-dependencies \
    build-base \
    git \
    libtool \
    automake \
    autoconf \
    wget \
    tar \
    xz \
    zlib-dev \
    cppunit-dev \
    openssl-dev \
    ncurses-dev \
    curl-dev \
    binutils \
    linux-headers \
 && apk add \
    ca-certificates \
    curl \
    ncurses \
    openssl \
    gzip \
    zip \
    zlib \
    s6 \
    su-exec \
    python2 \
    nodejs \
    npm \
    unrar@3.14 \
    findutils \
    mediainfo \
 && cd /tmp && mkdir libtorrent rtorrent \
 && cd libtorrent && wget -qO- https://github.com/rakshasa/libtorrent/archive/v${LIBTORRENT_VER}.tar.gz | tar xz --strip 1 \
 && cd ../rtorrent && wget -qO- https://github.com/rakshasa/rtorrent/releases/download/v${RTORRENT_VER}/rtorrent-${RTORRENT_VER}.tar.gz | tar xz --strip 1 \
 && cd /tmp \
 && git clone https://github.com/mirror/xmlrpc-c.git \
 && cd /tmp/xmlrpc-c/advanced && ./configure && make -j ${NB_CORES} && make install \
 && cd /tmp/libtorrent && ./autogen.sh && ./configure && make -j ${NB_CORES} && make install \
 && cd /tmp/rtorrent && ./autogen.sh && ./configure --with-xmlrpc-c && make -j ${NB_CORES} && make install \
 && strip -s /usr/local/bin/rtorrent \
 && mkdir /usr/flood && cd /usr/flood && wget -qO- https://github.com/jesec/flood/archive/v${FLOOD_VER}.tar.gz | tar xz --strip 1 \
 && npm install && npm cache clean --force \
 && apk del build-dependencies \
 && rm -rf /var/cache/apk/* /tmp/*

COPY rootfs /

RUN chmod +x /usr/local/bin/* /etc/s6.d/*/* /etc/s6.d/.s6-svscan/* \
 && cd /usr/flood/ && npm run build

VOLUME /data /flood-db

EXPOSE 3000 49184 49184/udp

LABEL description="BitTorrent client with WebUI front-end" \
      rtorrent="rTorrent BiTorrent client v$RTORRENT_VER" \
      libtorrent="libtorrent v$LIBTORRENT_VER" \
      maintainer="Wonderfall <wonderfall@targaryen.house>"

CMD ["run.sh"]
