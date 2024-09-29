#!/bin/bash
source $PWD/src/shell/base/colors.sh
source $PWD/src/shell/docker/docker_utils.sh

echo -e "${B_GREEN}>> Pulling the latest Docker images${RESET}"

# We always have caddy and blocky so no need to check beforehand
docker pull redpilllabs/caddy
docker pull ghcr.io/kyochikuto/sing-box-plus:latest

echo -e "${B_GREEN}>> Restarting Docker containers with the new images${RESET}"
source $PWD/src/shell/docker/restart_all_containers.sh

echo -e "${B_GREEN}<< Finished updating! >>${RESET}"
