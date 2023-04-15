#!/bin/bash

source $PWD/lib/shell/base/colors.sh
source $PWD/lib/shell/base/config.sh
source $PWD/lib/shell/os/os_utils.sh

IS_DOCKER_INSTALLED=$(fn_check_for_pkg docker-ce)
if [ "$IS_DOCKER_INSTALLED" = false ]; then
    echo -e "${B_GREEN}>> Checking for and installing required packages for Docker ${RESET}"
    apt install openssl \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Preparations
    if [ ! -d "/etc/apt/keyrings" ]; then
        mkdir -p /etc/apt/keyrings
    fi

    echo -e "${B_GREEN}>> Setting up Docker repositories ${RESET}"
    if [[ $DISTRO =~ "Ubuntu" ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo -e \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
    elif [[ $DISTRO =~ "Debian GNU/Linux" ]]; then
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo -e \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi

    # Fix permissions
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo -e "${B_GREEN}>> Installing Docker from official repository ${RESET}"
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    echo -e "${B_GREEN}>> Verifying Docker installation ${RESET}"
    docker run hello-world
    sleep 1

    if [ "$EUID" -ne 0 ]; then
        echo -e "${B_GREEN}>> Adding user to Docker group ${RESET}"
        usermod -aG docker $USER
    fi

    echo -e "${B_GREEN}>> Enabling Docker systemd services ${RESET}"
    systemctl daemon-reload
    systemctl enable --now docker
    systemctl enable --now containerd

    echo -e "${B_GREEN}<< Docker is now installed! >>${RESET}"
    # newgrp docker
fi
