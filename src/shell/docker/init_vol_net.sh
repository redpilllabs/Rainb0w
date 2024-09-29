#!/bin/bash
source $PWD/src/shell/base/colors.sh

if ! docker volume list | awk '{print $2}' | grep -q '^sockets$'; then
    echo -e "${B_GREEN}>> Creating shared Docker volume for UNIX sockets ${RESET}"
    docker volume create sockets >/dev/null
fi

if ! docker network list | awk '{print $2}' | grep -q '^caddy$'; then
    echo -e "${B_GREEN}>> Creating shared Docker network for Caddy's reverse proxy ${RESET}"
    docker network create --subnet=172.18.0.0/16 caddy >/dev/null
fi
