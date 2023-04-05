#!/bin/bash
source $PWD/lib/shell/base/colors.sh
source $PWD/lib/shell/docker/docker_utils.sh

echo -e "${B_GREEN}>> Pulling the latest Docker images${RESET}"

docker pull spx01/blocky

if [ -d "$HOME/Rainb0w_Home/xray" ]; then
    docker pull teddysun/xray
fi

if [ -d "$HOME/Rainb0w_Home/hysteria" ]; then
    docker pull tobyxdd/hysteria
fi

echo -e "${B_GREEN}>> Restarting Docker containers with the new images${RESET}"
source $PWD/lib/shell/docker/restart_all_containers.sh

echo -e "${B_GREEN}<< Finished updating! >>${RESET}"
