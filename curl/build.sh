#!/bin/sh
# Logging functions
log_info() { echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO] $*"; }
log_error() { echo "$(date +'%Y-%m-%d %H:%M:%S') [ERROR] $*" >&2; }

# settings
export CC=clang
export ARCH=armhf
export CURL_TAG=curl-8_14_1

# script dependencies
set -e

log_info "Installing dependencies..."
apk add git autoconf automake libtool wolfssl-dev build-base clang openssl-dev nghttp2-dev nghttp2-static libssh2-dev libssh2-static perl openssl-libs-static zlib-static

log_info "Removing old curl directory if exists..."
# remove curl dir if it is there
rm -rf curl || true

log_info "Cloning curl repository..."
git clone https://github.com/curl/curl.git --branch "$CURL_TAG" --depth 1

cd curl

log_info "Configuring build environment..."
# build
export CFLAGS="-Os -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -flto"
export LDFLAGS="-static -Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections"
export PKG_CONFIG="pkg-config --static"

autoreconf -fi

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
  --with-wolfssl

log_info "Starting make..."
make -j4 V=1 LDFLAGS="-static -all-static"

log_info "Stripping binary..."
strip src/curl

log_info "Verifying build outputs..."
# did we succeed?
ls -lah src/curl
file src/curl
ldd src/curl && { log_error "Dynamic dependencies found."; exit 1; } || log_info "Static binary confirmed."
./src/curl -V

log_info "Copying binary to release directory..."
# copy the binary out
mkdir -p /tmp/release/
mv src/curl /tmp/release/curl
log_info "Build and release completed successfully."
exit 0