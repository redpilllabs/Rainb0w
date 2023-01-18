#!/bin/bash

VERSION="1.4"
# Platform
DISTRO="$(awk -F= '/^NAME/{print $2}' /etc/os-release)"
DISTRO_VERSION=$(echo "$(awk -F= '/^VERSION_ID/{print $2}' /etc/os-release)" | tr -d '"')

# Path
DOCKER_DST_DIR=$HOME/Docker
DOCKER_SRC_DIR=/tmp/0xLem0nade/Docker

### Domains ###
declare -A SNI_DICT
SNI_DICT[CAMOUFLAGE_DOMAIN]=""
SNI_DICT[VLESS_TCP_SUBDOMAIN]=""
SNI_DICT[VLESS_GRPC_SUBDOMAIN]=""
SNI_DICT[VLESS_WS_SUBDOMAIN]=""
SNI_DICT[TROJAN_H2_SUBDOMAIN]=""
SNI_DICT[TROJAN_GRPC_SUBDOMAIN]=""
SNI_DICT[TROJAN_WS_SUBDOMAIN]=""
SNI_DICT[VMESS_WS_SUBDOMAIN]=""
SNI_DICT[HYSTERIA_SUBDOMAIN]=""
SNI_DICT[MTPROTO_SUBDOMAIN]=""

# Xray proxies
VLESS_TCP_UUID=$(cat /proc/sys/kernel/random/uuid)
VLESS_GRPC_UUID=$(cat /proc/sys/kernel/random/uuid)
VLESS_WS_UUID=$(cat /proc/sys/kernel/random/uuid)
VMESS_WS_UUID=$(cat /proc/sys/kernel/random/uuid)
TROJAN_H2_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
TROJAN_H2_PATH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
TROJAN_GRPC_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
TROJAN_WS_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

# Hysteria proxy
HYSTERIA_OBFS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

# Telegram proxy
TG_SECRET=$(head -c 16 /dev/urandom | xxd -ps)

# DNS filtering
DNS_FILTERING=false
