#!/bin/bash
source $PWD/src/shell/base/colors.sh

function fn_is_container_running() {
    local CID=$(docker ps -q -f status=running -f name=^/$1$)
    if [ "$CID" ]; then
        echo true
    else
        echo false
    fi
}

function fn_restart_docker_container() {
    local IS_CONTAINER_RUNNING=$(fn_is_container_running $1)
    if [ "$IS_CONTAINER_RUNNING" = true ]; then
        echo -e "${B_GREEN}>> Restarting Docker container '$1' for changes to take effect${RESET}"
        docker compose -f $HOME/Rainb0w_Home/$1/docker-compose.yml down --remove-orphans
        sleep 1
        docker compose -f $HOME/Rainb0w_Home/$1/docker-compose.yml up -d
    else
        echo -e "${B_GREEN}>> Starting Docker container: ${B_RED}$1${RESET}"
        docker compose -f $HOME/Rainb0w_Home/$1/docker-compose.yml up -d
    fi
}
