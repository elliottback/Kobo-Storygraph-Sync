#!/bin/sh
# Logging functions
log_info() { echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO] $*"; }
log_error() { echo "$(date +'%Y-%m-%d %H:%M:%S') [ERROR] $*" >&2; }

# settings
export CC="clang --target=armv7-linux-musleabihf"
export TINY_CURL_URL="https://curl.se/tiny/tiny-curl-8.4.0.tar.gz"

# script dependencies
set -e

log_info "Installing dependencies..."
apk add git autoconf automake libtool build-base clang openssl-dev nghttp2-dev nghttp2-static libssh2-dev libssh2-static perl openssl-libs-static zlib-static

log_info "Removing old curl directory if exists..."
rm -rf curl || true

log_info "Downloading tiny-curl tarball..."
wget -O tiny-curl.tar.gz "$TINY_CURL_URL"

log_info "Extracting tiny-curl..."
tar -xzf tiny-curl.tar.gz

# Find the extracted directory (should be tiny-curl-8.4.0)
EXTRACTED_DIR=$(tar -tf tiny-curl.tar.gz | head -1 | cut -f1 -d"/")

# Rename to 'curl' for compatibility with the rest of the script
mv "$EXTRACTED_DIR" curl
rm tiny-curl.tar.gz

cd curl

log_info "Configuring build environment..."
# build
export CFLAGS="--target=armv7-linux-musleabihf -Os -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -flto"
export LDFLAGS="-static -Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections"
export PKG_CONFIG="pkg-config --static"

autoreconf -fi

./configure \
  --host=armv7-linux-musleabihf \
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
  --with-openssl

log_info "Applying patches..."
sed -i 's/#ifndef NO_SHA256/#if defined(OPENSSL_EXTRA) \&\& !defined(NO_SHA256)/' lib/sha256.c

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