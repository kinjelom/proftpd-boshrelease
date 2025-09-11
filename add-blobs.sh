#!/bin/bash

set -eu

source ./src/meta-info/blobs-versions.env
source ./rel.env
unset BOSH_ALL_PROXY

mkdir -p "$TMP_DIR"

function down_add_blob {
  BLOBS_GROUP=$1
  FILE=$2
  URL=$3
  if [ ! -f "blobs/${BLOBS_GROUP}/${FILE}" ];then
    echo "Downloads resource from the Internet ($URL -> $TMP_DIR/$FILE)"
    curl -L "$URL" --output "$TMP_DIR/$FILE"
    echo "Adds blob ($TMP_DIR/$FILE -> $BLOBS_GROUP/$FILE), starts tracking blob in config/blobs.yml for inclusion in packages"
    bosh add-blob "$TMP_DIR/$FILE" "$BLOBS_GROUP/$FILE"
  fi
}

down_add_blob "proftpd" "proftpd-${PROFTPD_VERSION}.tar.gz" "${PROFTPD_URL}"
down_add_blob "proftpd" "mod_prometheus-${MOD_PROMETHEUS_VERSION}.src.zip" "${MOD_PROMETHEUS_URL}"
down_add_blob "proftpd" "mod_auth_rest-${MOD_AUTH_REST_VERSION}.src.zip" "${MOD_AUTH_REST_URL}"
down_add_blob "mariadb" "mariadb-connector-c-${MARIADB_CC_VERSION}-src.tar.gz" "${MARIADB_CC_URL}"

down_add_blob "devs" "libmicrohttpd-${LIBMICROHTTPD_VERSION}.tar.gz" "${LIBMICROHTTPD_URL}"
down_add_blob "devs" "sqlite-autoconf-${SQLITE_VERSION}.tar.gz" "${SQLITE_URL}"
down_add_blob "devs" "curl-${CURL_VERSION}.tar.gz" "${CURL_URL}"
down_add_blob "devs" "openssl-${OPENSSL_VERSION}.tar.gz" "${OPENSSL_URL}"
down_add_blob "devs" "nghttp2-${NGHTTP2_VERSION}.tar.gz" "${NGHTTP2_URL}"
down_add_blob "devs" "zlib-${ZLIB_VERSION}.tar.gz" "${ZLIB_URL}"

down_add_blob "fsaa" "fsaa_${FSAA_VERSION}.tar.gz" "${FSAA_URL}"

echo "Upload previously added blobs that were not yet uploaded to the blobstore. Updates config/blobs.yml with returned blobstore IDs."
bosh upload-blobs

echo "Download blobs into blobs/ based on config/blobs.yml"
bosh sync-blobs
