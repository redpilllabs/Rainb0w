#!/bin/bash

VERSION="2.0"
# Platform
DISTRO="$(awk -F= '/^NAME/{print $2}' /etc/os-release)"
DISTRO_VERSION=$(echo "$(awk -F= '/^VERSION_ID/{print $2}' /etc/os-release)" | tr -d '"')

# General
EXISTING_SETUP=false

# Path
DOCKER_HOME=$HOME/Docker
CADDY_CONFIG_FILE="${DOCKER_HOME}/caddy/etc/caddy.json"
XRAY_CONFIG_FILE="${DOCKER_HOME}/xray/etc/xray.json"
HYSTERIA_CONFIG_FILE="${DOCKER_HOME}/hysteria/etc/hysteria.json"
HYSTERIA_CLIENT_CONFIG_FILE="${DOCKER_HOME}/hysteria/client/hysteria.json"
MTPROTOPY_CONFIG_FILE="${DOCKER_HOME}/hysteria/config/config.toml"
MTPROTOPY_USERS_FILE="${DOCKER_HOME}/hysteria/config/users.toml"
BLOCKY_CONFIG_FILE="${DOCKER_HOME}/blocky/etc/config.yml"

### Domains ###
declare -A SNI_DICT

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
HYSTERIA_PORT=$(shuf -i 1025-65000 -n 1)
HYSTERIA_OBFS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

# Telegram proxy
TG_SECRET=$(head -c 16 /dev/urandom | xxd -ps)

# Access control
BLOCK_KEYWORDS=(porn xxx sex sxy hardcore erotic adult pussy anal cock jizz myonlyfans openload gallery galleries)
BLOCK_IRAN_OUT_STATUS=""
BLOCK_IRAN_OUT_STATUS_COLOR=$B_RED
BLOCK_CHINA_IN_OUT_STATUS=""
BLOCK_CHINA_IN_OUT_STATUS_COLOR=$B_RED
BLOCK_PORN_STATUS=""
BLOCK_PORN_STATUS_COLOR=$B_RED

# Kernel Optimization
KERNEL_TUNING_STATUS=""
KERNEL_TUNING_STATUS_COLOR=$B_RED

# Kernel Optimization
ZRAM_STATUS=""
ZRAM_STATUS_COLOR=$B_RED
