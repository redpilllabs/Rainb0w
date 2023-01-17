#!/bin/bash

function fn_setup_docker() {
    echo -e "${GREEN}Creating Docker volumes and networks ${RESET}"
    docker_volume_output=$(docker volume inspect sockets | grep Created)
    if [ -z "${docker_volume_output}" ] || [[ $docker_volume_output == *"No such volume"* ]]; then
        docker volume create sockets
    fi
    docker_network_output=$(docker network inspect caddy | grep Created)
    if [ -z "${docker_network_output}" ] || [[ $docker_network_output == *"No such network"* ]]; then
        docker network create caddy
    fi
}

function fn_docker_container_launcher() {
    CID=$(docker ps -q -f status=running -f name=^/$1$)
    if [ ! "${CID}" ]; then
        docker compose -f $DOCKER_DST_DIR/$1/docker-compose.yml up -d
    else
        docker compose -f $DOCKER_DST_DIR/$1/docker-compose.yml down --remove-orphans
        sleep 1
        docker compose -f $DOCKER_DST_DIR/$1/docker-compose.yml up -d
    fi
}

function fn_spinup_docker_containers() {
    trap - INT
    echo -e "${GREEN}\nLaunching Caddy...${RESET}"
    fn_docker_container_launcher caddy
    echo -e "${CYAN}Waiting 10 seconds for TLS certificates to fully download..."
    sleep 10
    echo -e "${GREEN}Spinning up proxy Docker container...${RESET}"
    if [ $DNS_FILTERING = true ]; then
        echo -e "\nLaunching blocky DNS server..."
        fn_docker_container_launcher blocky
        sleep 1
    fi
    if [ ! -z "${VLESS_TCP_SUBDOMAIN}" ] || [ ! -z "${VLESS_GRPC_SUBDOMAIN}" ] || [ ! -z "${VLESS_WS_SUBDOMAIN}" ] || [ ! -z "${TROJAN_H2_SUBDOMAIN}" ] || [ ! -z "${TROJAN_GRPC_SUBDOMAIN}" ] || [ ! -z "${TROJAN_WS_SUBDOMAIN}" ] || [ ! -z "${VMESS_WS_SUBDOMAIN}" ]; then
        echo -e "\nLaunching Xray..."
        fn_docker_container_launcher xray
        sleep 1
    fi
    if [ ! -z "${HYSTERIA_SUBDOMAIN}" ]; then
        echo -e "\nLaunching Hysteria..."
        fn_docker_container_launcher hysteria
        sleep 1
    fi
    if [ ! -z "${MTPROTO_SUBDOMAIN}" ]; then
        echo -e "\nLaunching MTProtoPy..."
        fn_docker_container_launcher mtproto
    fi
}

function fn_install_docker() {
    trap - INT
    dpkg --status docker-ce &>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Docker is already installed! ${RESET}"
    else
        echo -e "${B_GREEN}### Installing required packages for Docker \n  ${RESET}"
        sudo apt install -y \
            openssl \
            ca-certificates \
            curl \
            gnupg \
            lsb-release \
            jq

        # Preparations
        if [ ! -d "/etc/apt/keyrings" ]; then
            sudo mkdir -p /etc/apt/keyrings
        fi

        echo -e "${GREEN}Setting up Docker repositories \n ${RESET}"
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

        echo -e "${GREEN}Installing Docker from official repository \n ${RESET}"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

        echo -e "${GREEN}Enabling Rootless Docker Execution \n ${RESET}"
        sudo usermod -aG docker $USER
        sudo systemctl daemon-reload
        sudo systemctl enable --now docker
        sudo systemctl enable --now containerd

        # Test installation
        sudo docker run hello-world

        echo -e "${B_GREEN}*** Docker is now installed! *** \n ${RESET}"
        # newgrp docker
    fi
}
