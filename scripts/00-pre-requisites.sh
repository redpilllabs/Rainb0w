#!/bin/bash

fn_check_package_installed() {
    dpkg --status $1 &>/dev/null
    if [ $? -eq 0 ]; then
        echo "$1: Already installed"
    else
        sudo apt-get install -y $1
    fi
}

if [[ $DISTRO =~ "Ubuntu" || $DISTRO =~ "Debian" ]]; then
    fn_check_package_installed jq
    fn_check_package_installed libfribidi-bin
    # if [[ ! -f /usr/bin/yq ]]; then
    #     sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&
    #         sudo chmod +x /usr/bin/yq
    # fi
fi
