#!/bin/bash

# Allow execution permission
find $PWD -name "*.sh" -exec chmod +x {} \;

source $PWD/lib/shell/base/colors.sh
source $PWD/lib/shell/base/config.sh
source $PWD/lib/shell/os/os_utils.sh

trap '' INT

# OS check
if ! [[ "$DISTRO" =~ "Ubuntu" || "$DISTRO" =~ "Debian" ]]; then
    echo "$DISTRO"
    echo -e "${B_RED}This installer only supports Debian and Ubuntu OS!${RESET}"
    exit 0
else
    # Version check
    if [[ "$DISTRO" =~ "Ubuntu" ]]; then
        if [ ! "$DISTRO_VERSION" == "20.04" ] && [ ! "$DISTRO_VERSION" == "22.04" ]; then
            echo "Your version of Ubuntu is not supported! Only 20.04 and 22.04 versions are supported."
            exit 0
        fi
    elif [[ "$DISTRO" =~ "Debian GNU/Linux" ]]; then
        if [ ! "$DISTRO_VERSION" == "11" ]; then
            echo "Your version of Debian is not supported! Minimum required version is 11"
            exit 0
        else
            # Debian has a quirk that usually comes with an old Kernel that
            # does not have the corresponding headers and modules package available
            apt update
            current_kernel=$(uname -r)
            available_kernels=$(apt-cache search linux-image | grep -oP '[0-9]\.[0-9]+\.[0-9]+-[0-9]+' | sort --version-sort)
            latest_kernel=$(echo "$available_kernels" | tail -n 1)
            if [[ "$latest_kernel" > "$current_kernel" ]]; then
                fn_check_and_install_pkg linux-image-$latest_kernel-amd64
                fn_check_and_install_pkg linux-headers-$latest_kernel-amd64
                echo -e "${B_GREEN}\n\nThere's a newer kernel available for your OS: $available_kernel${RESET}"
                echo -e "${B_RED}You're server is now going to reboot to load the new kernel and the extra moduels required${RESET}"
                echo -e "${B_GREEN}After booting up, run the script again to proceed!${RESET}"
                systemctl reboot
                exit
            else
                fn_check_and_install_pkg linux-image-amd64
                fn_check_and_install_pkg linux-headers-amd64
            fi
        fi
    fi
fi

# Check for root permissions
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./run.sh)"
    exit
fi

# Install pre-requisites
if [ ! -d "$HOME/Rainb0w_Home" ]; then
    fn_install_python_packages
    clear
fi

function installer_menu() {
    echo -ne "
Express: Only deploys Xray proxies (VLESS, VMESS, Trojan)
Custom:  Select available proxies to deploy (Xray, Hysteria, MTProto)
Restore: Restore a previous installation's configuration and users

Select installation type:

${GREEN}1)${RESET} Express
${GREEN}2)${RESET} Custom
${GREEN}3)${RESET} Restore
${RED}0)${RESET} Exit

Choose an option: "
    read -r ans
    case $ans in
    3)
        clear
        python3 $PWD/lib/configurator.py "Restore"
        PYTHON_EXIT_CODE=$?
        if [ $PYTHON_EXIT_CODE -ne 0 ]; then
            echo "Python configurator did not finish successfully!"
            exit
        fi
        source $PWD/lib/shell/deploy.sh "Restore"
        ;;
    2)
        clear
        # Cleanup and copy all the template files to let the admin select among them
        rm -rf $HOME/Rainb0w_Home
        mkdir $HOME/Rainb0w_Home
        cp -r ./Docker/* $HOME/Rainb0w_Home/
        python3 $PWD/lib/configurator.py "Custom"
        PYTHON_EXIT_CODE=$?
        if [ $PYTHON_EXIT_CODE -ne 0 ]; then
            echo "Python configurator did not finish successfully!"
            exit
        fi
        source $PWD/lib/shell/deploy.sh "Custom"
        ;;
    1)
        clear
        # Cleanup and copy only the essential templates to deploy Xray since we're going Express
        rm -rf $HOME/Rainb0w_Home
        mkdir $HOME/Rainb0w_Home
        cp -r ./Docker/caddy $HOME/Rainb0w_Home/
        cp -r ./Docker/blocky $HOME/Rainb0w_Home/
        cp -r ./Docker/wordpress $HOME/Rainb0w_Home/
        cp -r ./Docker/xray $HOME/Rainb0w_Home/
        cp ./Docker/rainb0w_config.toml $HOME/Rainb0w_Home/
        cp ./Docker/rainb0w_users.toml $HOME/Rainb0w_Home/
        python3 $PWD/lib/configurator.py "Express"
        PYTHON_EXIT_CODE=$?
        if [ $PYTHON_EXIT_CODE -ne 0 ]; then
            echo "Python configurator did not finish successfully!"
            exit
        fi
        source $PWD/lib/shell/deploy.sh "Express"
        ;;
    0)
        exit
        ;;
    *)
        fn_fail
        clear
        installer_menu
        ;;
    esac
}

function main() {
    if [ -d "$HOME/Rainb0w_Home" ]; then
        # We have an existing installation, so let's present the dashboard to change settings
        python3 $PWD/lib/dashboard.py
        PYTHON_EXIT_CODE=$?
        if [ $PYTHON_EXIT_CODE -ne 0 ]; then
            source $PWD/lib/shell/docker/restart_all_containers.sh
            exit
        else
            exit
        fi
    else
        # This is a new installation
        installer_menu
    fi
}

main
