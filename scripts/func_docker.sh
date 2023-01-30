#!/bin/bash

function fn_is_container_running() {
    local CID=$(docker ps -q -f status=running -f name=^/$1$)
    if [ "$CID" ]; then
        echo true
    else
        echo false
    fi
}

function fn_setup_docker_vols_networks() {
    echo -e "${B_GREEN}Creating Docker volumes and networks ${RESET}"
    docker volume create sockets
    docker network create caddy
}

function fn_start_docker_container() {
    local IS_CONTAINER_RUNNING=$(fn_is_container_running $1)
    if [ "$IS_CONTAINER_RUNNING" = true ]; then
        echo -e "${B_YELLOW}\n$1 Docker container is already running. Restarting it for changes to take affect...${RESET}"
        docker compose -f $DOCKER_HOME/$1/docker-compose.yml down --remove-orphans
        sleep 1
        docker compose -f $DOCKER_HOME/$1/docker-compose.yml up -d
    else
        echo -e "${B_GREEN}\nStarting $1 Docker container..."
        docker compose -f $DOCKER_HOME/$1/docker-compose.yml up -d
    fi
}

function fn_stop_all_docker_containers() {
    echo -e "${B_YELLOW}Stopping all running proxy containers ${RESET}"

    if [ "$(fn_is_container_running xray)" = true ]; then
        docker compose -f $DOCKER_HOME/xray/docker-compose.yml down --remove-orphans
    fi

    if [ "$(fn_is_container_running xray)" = true ]; then
        docker compose -f $DOCKER_HOME/mtprotopy/docker-compose.yml down --remove-orphans
    fi

    if [ "$(fn_is_container_running xray)" = true ]; then
        docker compose -f $DOCKER_HOME/hysteria/docker-compose.yml down --remove-orphans
    fi

    if [ "$(fn_is_container_running xray)" = true ]; then
        docker compose -f $DOCKER_HOME/blocky/docker-compose.yml down --remove-orphans
    fi

    if [ "$(fn_is_container_running xray)" = true ]; then
        docker compose -f $DOCKER_HOME/caddy/docker-compose.yml down --remove-orphans
    fi

    echo -e "${B_GREEN}<<< All Docker containers unloaded to the dock! >>> ${RESET}"
}

function fn_install_docker() {
    trap - INT
    local IS_DOCKER_INSTALLED=$(fn_check_for_pkg docker-ce)
    if [ "$IS_DOCKER_INSTALLED" = true ]; then
        echo -e "${B_GREEN}Docker is already installed! ${RESET}"
    else
        echo -e "${B_GREEN}Checking for and installing required packages for Docker ${RESET}"
        fn_check_and_install_pkg openssl
        fn_check_and_install_pkg ca-certificates
        fn_check_and_install_pkg curl
        fn_check_and_install_pkg gnupg
        fn_check_and_install_pkg lsb-release

        # Preparations
        if [ ! -d "/etc/apt/keyrings" ]; then
            sudo mkdir -p /etc/apt/keyrings
        fi

        echo -e "${B_GREEN}Setting up Docker repositories ${RESET}"
        if [[ $DISTRO =~ "Ubuntu" ]]; then
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo -e \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        elif [[ $DISTRO =~ "Debian GNU/Linux" ]]; then
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo -e \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        fi

        # Fix permissions
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo -e "${B_GREEN}Installing Docker from official repository ${RESET}"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

        # Test installation
        sudo docker run hello-world
        echo -e "${B_GREEN}\n*** Docker is now installed! *** \n ${RESET}"
        sleep 2

        if [ ! "$USER" = "root" ]; then
            echo -e "${B_YELLOW}\nNOTE: This is not the root user and I need to apply changes to their group,"
            echo -e "but doing so will make this script exit! You need to re-run the installer afterwards!"
            echo -e "${B_GREEN}\nAdding user to Docker group ${RESET}"
            sudo usermod -aG docker $USER
            sudo systemctl daemon-reload
            sudo systemctl enable --now docker
            sudo systemctl enable --now containerd

            echo -e "${BB_CYAN}\nPlease re-run the 'installer.sh' to continue!\n"
            newgrp docker
        fi
    fi
}
