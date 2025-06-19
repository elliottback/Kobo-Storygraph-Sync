#!/bin/sh

# settings
export CC=clang
export ARCH=armhf
export TAG=curl-8_14_1

# script
set -e

git clone https://github.com/curl/curl.git --depth 1 --branch $TAG

cd curl

apk add build-base clang openssl-dev nghttp2-dev nghttp2-static libssh2-dev libssh2-static perl openssl-libs-static zlib-static

export CFLAGS="-Os -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -flto"
export LDFLAGS="-static -Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections"
export PKG_CONFIG="pkg-config --static"

./configure \
  --disable-shared \
  --enable-static \
  --disable-ldap \
  --disable-ipv6 \
  --with-ssl \
  --with-libssh2 \
  --disable-docs \
  --disable-manual \
  --without-libpsl \
  --disable-file \
  --disable-ftp \
  --disable-gopher \
  --disable-imap \
  --disable-ldap \
  --disable-mqtt \
  --disable-pop3 \
  --disable-proxy \
  --disable-rtmp \
  --disable-rtsp \
  --disable-scp \
  --disable-sftp \
  --disable-smtp \
  --disable-telnet \
  --disable-tftp \
  --disable-unix-sockets \
  --disable-verbose \
  --disable-versioned-symbols \
  --disable-http-auth \
  --disable-doh \
  --disable-mime \
  --disable-dateparse \
  --disable-netrc \
  --disable-dnsshuffle \
  --disable-progress-meter \
  --enable-maintainer-mode \
  --enable-werror \
  --without-gssapi \
  --without-libidn2 \
  --without-libpsl \
  --without-librtmp \
  --without-libssh2 \
  --without-nghttp2 \
  --without-ntlm-auth \
  --with-wolfssl=[install prefix]

make -j4 V=1 LDFLAGS="-static -all-static"

strip src/curl

# did we succeed?
ls -lah src/curl
file src/curl
ldd src/curl && exit 1 || true
./src/curl -V

# copy the binary out
mkdir -p /tmp/release/
mv src/curl /tmp/release/curl
exit 0