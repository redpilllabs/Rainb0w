#!/bin/bash

function fn_install_requirements() {
    if [[ $DISTRO =~ "Ubuntu" || $DISTRO =~ "Debian" ]]; then
        # Update OS
        echo -e " ${B_GREEN} ### Updating the repository cache... \n ${RESET}"
        sudo apt update
        sudo apt upgrade -y

        # Install required packages
        echo -e "${B_GREEN}### Installing required packages...\n  ${RESET}"
        sudo apt install -y ufw uuid openssl iptables fail2ban zram-tools linux-modules-extra-$(uname -r)

        echo -e "${B_GREEN}### Enabling zram swap to optimize memory usage... \n  ${RESET}"
        echo -e "ALGO=zstd" | sudo tee -a /etc/default/zramswap
        echo -e "PERCENT=50" | sudo tee -a /etc/default/zramswap
        sudo systemctl restart zramswap.service

        echo -e "${B_GREEN}### Setting up ufw firewall... \n  ${RESET}"
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow ssh
        sudo ufw allow 53
        sudo ufw allow http
        sudo ufw allow https
        sudo ufw allow domain-s

        echo -e "${On_IYellow}${BBlack}Enter ${BRed}'y'${On_IYellow}${BBlack} below to activate the firewall ↴ ${RESET}"
        sudo ufw enable
        sudo ufw status verbose

        echo -e "${B_GREEN}*** Preparing Docker Installation ***\n ${RESET}"

        echo -e "${B_GREEN}Removing any previous installations \n ${RESET}"
        sudo apt-get remove docker docker-engine docker.io containerd runc

        echo -e "${B_GREEN}Installing Pre-requisites \n ${RESET}"
        sudo apt-get update
        sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release \
            uidmap

        if [[ $DISTRO =~ "Ubuntu" ]]; then
            echo -e "${B_GREEN}Setting up Docker repositories \n ${RESET}"
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            sudo apt-get update

            echo -e \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        elif [[ $DISTRO =~ "Debian" ]]; then
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo -e \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        fi

        echo -e "${B_GREEN}Installing Docker from official repository \n ${RESET}"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

        echo -e "${B_GREEN}Enabling Rootless Docker Execution \n ${RESET}"
        sudo usermod -aG docker $USER
        sudo systemctl daemon-reload
        sudo systemctl enable --now docker
        sudo systemctl enable --now containerd

        # Test installation
        sudo docker run hello-world

        echo -e "${B_GREEN}*** Docker is now installed! *** \n ${RESET}"
        newgrp docker
    else
        echo -e "${BRed}This installer only supports Debian and Ubuntu OS!${RESET}"
    fi
}
