#!/bin/bash
source $PWD/lib/shell/base/colors.sh

function fn_check_for_pkg() {
    if [ $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        echo false
    else
        echo true
    fi
}

function fn_check_and_install_pkg() {
    local IS_INSTALLED=$(fn_check_for_pkg $1)
    if [ $IS_INSTALLED = false ]; then
        echo -e "${B_GREEN}>> Installing '$1'... ${RESET}"
        apt install -y $1
    fi
}

function fn_install_python_packages() {
    echo -e "${B_GREEN}>> Checking for requried Python packages${RESET}"
    apt update && apt upgrade -y
    fn_check_and_install_pkg python3-pip
    pip3 install --quiet -r $PWD/requirements.txt
}
