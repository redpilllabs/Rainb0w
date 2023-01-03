#!/bin/bash

function fn_upgrade_os() {
    # Update OS
    echo -e " ${B_GREEN} ### Updating the operating system \n ${RESET}"
    sudo apt update
    sudo apt upgrade -y
}

function fn_setup_zram() {
    echo -e "${B_GREEN}### Installing required packages for ZRam swap \n  ${RESET}"
    sudo apt install -y zram-tools linux-modules-extra-$(uname -r)

    echo -e "${B_GREEN}### Enabling zram swap to optimize memory usage \n  ${RESET}"
    echo "ALGO=zstd" | sudo tee -a /etc/default/zramswap
    echo "PERCENT=50" | sudo tee -a /etc/default/zramswap
    sudo systemctl restart zramswap.service
}

function fn_setup_firewall() {
    echo -e "${B_GREEN}### Installing ufw firewall \n  ${RESET}"
    sudo apt install -y ufw

    echo -e "${B_GREEN}### Setting up ufw firewall \n  ${RESET}"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw allow 554/udp

    echo -e "${IBG_YELLOW}${B_BLACK}Enter ${B_RED}'y'${IBG_YELLOW}${B_BLACK} below to activate the firewall ↴ ${RESET}"
    sudo ufw enable
    sudo ufw status verbose
}

function fn_block_outbound_connections_to_iran() {
    echo -e "${B_GREEN}### Installing required packages for GeoIP blocking \n  ${RESET}"
    sudo apt install -y \
        xtables-addons-dkms \
        xtables-addons-common \
        libtext-csv-xs-perl \
        libmoosex-types-netaddr-ip-perl \
        pkg-config \
        iptables-persistent \
        lsb-release \
        gzip \
        wget

    # Download the latest GeoIP database
    MON=$(date +"%m")
    YR=$(date +"%Y")
    sudo mkdir /usr/share/xt_geoip
    sudo wget "https://download.db-ip.com/free/dbip-country-lite-${YR}-${MON}.csv.gz" -O /usr/share/xt_geoip/dbip-country-lite.csv.gz
    sudo gunzip /usr/share/xt_geoip/dbip-country-lite.csv.gz

    # Convert CSV database to binary format for xt_geoip
    DISTRO_VERSION=$(lsb_release -sr)
    if [[ "$DISTRO" =~ "Ubuntu" ]]; then
        if (($(echo "$DISTRO_VERSION == 20.04" | bc -l))); then
            sudo /usr/lib/xtables-addons/xt_geoip_build -D /usr/share/xt_geoip/ -S /usr/share/xt_geoip/
        elif (($(echo "$DISTRO_VERSION == 22.04" | bc -l))); then
            sudo /usr/libexec/xtables-addons/xt_geoip_build -s -i /usr/share/xt_geoip/dbip-country-lite.csv.gz
        fi
    elif [[ "$DISTRO" =~ "Debian GNU/Linux" ]]; then
        if (($(echo "$DISTRO_VERSION == 11" | bc -l))); then
            sudo /usr/libexec/xtables-addons/xt_geoip_build -s -i /usr/share/xt_geoip/dbip-country-lite.csv.gz
        fi
    fi

    # Load xt_geoip kernel module
    modprobe xt_geoip
    lsmod | grep ^xt_geoip

    # Block outgoing connections to Iran
    sudo iptables -A OUTPUT -m geoip --dst-cc IR -j DROP

    # Save and cleanup
    sudo iptables-save | sudo tee /etc/iptables/rules.v4
    sudo ip6tables-save | sudo tee /etc/iptables/rules.v6
    sudo rm /usr/share/xt_geoip/dbip-country-lite.csv
}

function fn_harden_ssh_security() {
    echo -e "${B_GREEN}### Installing fail2ban \n  ${RESET}"
    sudo apt install -y fail2ban

    echo -e "${B_GREEN}### Hardening SSH against brute-force \n  ${RESET}"
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    fail2ban_contents="[sshd]
        enabled = true
        port = ssh
        filter = sshd
        logpath = /var/log/auth.log
        maxretry = 5
        findtime = 300
        bantime = 3600
        ignoreip = 127.0.0.1"
    fail2ban_contents="${fail2ban_contents// /}"
    echo -e "${fail2ban_contents}" | sudo tee /etc/fail2ban/jail.local >/dev/null
    sudo systemctl restart fail2ban.service
}

function fn_install_docker() {
    # Update OS
    echo -e " ${B_GREEN} ### Updating the repository cache \n ${RESET}"
    sudo apt update
    sudo apt upgrade -y

    echo -e "${B_GREEN}### Installing required packages for Docker \n  ${RESET}"
    sudo apt install -y \
        openssl \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    if [[ $DISTRO =~ "Ubuntu" ]]; then
        echo -e "${GREEN}Setting up Docker repositories \n ${RESET}"
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt-get update

        echo -e \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    elif [[ $DISTRO =~ "Debian GNU/Linux" ]]; then
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo -e \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi

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
}
