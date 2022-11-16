#!/bin/bash
# Load config and variables
source config.sh

if [[ $DISTRO =~ "Ubuntu" || $DISTRO =~ "Debian" ]]; then
    # Update OS
    echo -e " ${BGreen} ### Updating the repository cache... \n $Color_Off"
    sudo apt update
    sudo apt upgrade -y

    # Install required packages
    echo "${BGreen}### Installing required packages...\n  ${Color_Off}"
    sudo apt install -y ufw uuid openssl iptables fail2ban zram-tools linux-modules-extra-$(uname -r)

    echo "${BGreen}### Enabling zram swap to optimize memory usage... \n  ${Color_Off}"
    echo "ALGO=zstd" | sudo tee -a /etc/default/zramswap
    echo "PERCENT=50" | sudo tee -a /etc/default/zramswap
    sudo systemctl restart zramswap.service

    echo "${BGreen}### Setting up ufw firewall... \n  ${Color_Off}"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 53
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw allow domain-s

    echo -e "${On_IYellow}${BBlack}Enter ${BRed}'y'${On_IYellow}${BBlack} below to activate the firewall ↴ ${Color_Off}"
    sudo ufw enable
    sudo ufw status verbose

    echo "${BGreen}*** Finished! *** \n ${Color_Off}"
else
    echo "This installer only supports Debian and Ubuntu OS!"
fi
