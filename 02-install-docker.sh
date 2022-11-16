#!/bin/bash
# Load config and variables
source config.sh

if [[ $DISTRO =~ "Ubuntu" || $DISTRO =~ "Debian" ]]; then
  echo -e "${BGreen}*** Preparing Docker Installation ***\n ${Color_Off}"

  echo -e "${BGreen}Removing any previous installations \n ${Color_Off}"
  sudo apt-get remove docker docker-engine docker.io containerd runc

  echo -e "${BGreen}Installing Pre-requisites \n ${Color_Off}"
  sudo apt-get update
  sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    uidmap

  if [[ $DISTRO =~ "Ubuntu" ]]; then
    echo -e "${BGreen}Setting up Docker repositories \n ${Color_Off}"
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

  echo -e "${BGreen}Installing Docker from official repository \n ${Color_Off}"
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  echo -e "${BGreen}Enabling Rootless Docker Execution \n ${Color_Off}"
  sudo usermod -aG docker $USER
  sudo systemctl daemon-reload
  sudo systemctl enable --now docker
  sudo systemctl enable --now containerd

  # Test installation
  sudo docker run hello-world

  echo -e "${BGreen}*** Docker is now installed! *** \n ${Color_Off}"
  newgrp docker
else
  echo -e "${BRed}This installer only supports Debian and Ubuntu OS!${Color_Off}"
fi
