#!/bin/bash

VERSION="1.0"
# Platform
DISTRO="$(awk -F= '/^NAME/{print $2}' /etc/os-release)"
DISTRO_VERSION=$(echo "$(awk -F= '/^VERSION_ID/{print $2}' /etc/os-release)" | tr -d '"')

# Path
DOCKER_DST_DIR=$HOME/Docker
DOCKER_SRC_DIR=/tmp/0xLem0nade/Docker

### Server ###
DOMAIN=""
#TODO: Remove the need for email for privacy reasons!
EFF_EMAIL=""
SNI_ARR=()
# Xray proxies
XTLS_UUID=$(uuid)
TROJAN_H2_PASSWORD=$(openssl rand -base64 8)
TROJAN_GRPC_PASSWORD=$(openssl rand -base64 8)
TROJAN_GRPC_SERVICENAME=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
TROJAN_WS_PASSWORD=$(openssl rand -base64 8)
TROJAN_WS_PATH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
VMESS_WS_UUID=$(uuid)
VMESS_WS_PATH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
XTLS_SUBDOMAIN=""
TROJAN_H2_SUBDOMAIN=""
TROJAN_GRPC_SUBDOMAIN=""
TROJAN_WS_SUBDOMAIN=""
VMESS_WS_SUBDOMAIN=""
# Hysteria proxy
HYSTERIA_PASSWORD=$(openssl rand -base64 8)
HYSTERIA_SUBDOMAIN=""
# Telegram proxy
TG_SECRET=$(head -c 16 /dev/urandom | xxd -ps)
MTPROTO_SUBDOMAIN=""
