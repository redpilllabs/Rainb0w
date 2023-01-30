#!/bin/bash

source $PWD/scripts/func_docker.sh
source $PWD/scripts/func_performance.sh
source $PWD/scripts/func_ac.sh
source $PWD/scripts/func_dns.sh
source $PWD/scripts/func_caddy.sh
source $PWD/scripts/func_xray.sh
source $PWD/scripts/func_hysteria.sh
source $PWD/scripts/func_mtproto.sh

#### General Functions #####

function fn_exit() {
    echo "Quitting!"
    exit 0
}
function fn_fail() {
    echo "Wrong option!"
    sleep 1
}

function fn_prompt_domain() {
    echo -e "\n\n"
    echo -e "Enter the full domain or SNI (e.g: ${GREEN}example.com${RESET} or ${GREEN}xxx.example.com${RESET})"
    echo -e "${B_YELLOW}(i)${RESET} To clear the entry, press 'Enter' when the field is blank.\n"
    while true; do
        local input=""
        read -e -r -p "Domain/SNI for ${1}: " -i "${SNI_DICT[$2]}" input

        if [[ ! -z "$input" ]]; then
            if [[ ! "${SNI_DICT[$2]}" = "$input" ]]; then
                local UNIQUE_VALS=$(echo "${SNI_DICT[@]}" | xargs)
                local OTHER_VALS=${UNIQUE_VALS/${SNI_DICT[$2]}/}
                if [[ " $OTHER_VALS " =~ .*\ $input\ .* ]]; then
                    echo -e "\n${B_RED}ERROR: This domain or SNI is already reserved for another proxy, enter another one!${RESET}"
                    continue
                else
                    SNI_DICT["$2"]=$input
                    break
                fi
            else
                break
            fi
        else
            SNI_DICT[$2]=""
            break
        fi
    done
}

# Prints text either colored or uncolored with a typewriter effect
function fn_typewriter() {
    if [ $# -gt 2 ]; then
        echo -e "Illegal number of args passed!"
        exit 1
    fi

    string=$1
    if [ $# -gt 1 ]; then
        for ((i = 0; i <= ${#string}; i++)); do
            printf "$2%b$RESET" "${string:$i:1}"
            sleep 0.$(((RANDOM % 2) + 1))
        done
    else
        for ((i = 0; i <= ${#string}; i++)); do
            printf "%s" "${string:$i:1}"
            sleep 0.$(((RANDOM % 2) + 1))
        done
    fi
}

function fn_upgrade_os() {
    trap - INT
    # Update OS
    echo -e " ${B_GREEN}Updating the operating system \n ${RESET}"
    sudo apt update
    sudo apt upgrade -y
}

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
        echo -e "${B_YELLOW}\n'$1' is missing! Installing now... ${RESET}"
        sudo apt install -y $1
    fi
}

function fn_install_required_packages() {
    fn_check_and_install_pkg zip
    fn_check_and_install_pkg logrotate
    fn_check_and_install_pkg wget
    fn_check_and_install_pkg curl
    fn_check_and_install_pkg jq
    if [ ! -f "/usr/local/bin/yq" ]; then
        echo -e "${B_YELLOW}\n'yq' is missing! Installing now... ${RESET}"
        sudo wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq &&
            sudo chmod +x /usr/local/bin/yq
    fi
}

function fn_copy_files() {
    echo -e "${B_GREEN}Copying required files to ${DOCKER_HOME}${RESET}"
    if [ -d "$DOCKER_HOME" ]; then
        rm -rf $DOCKER_HOME
    fi
    cp -r $PWD/Docker/ $DOCKER_HOME
}

function fn_clear_existing_setup() {
    echo -e "\n\n"
    read -p "$(echo -e "${B_YELLOW}Do you want me to erase the existing setup and start a new one? (y/N)${RESET}")" confirm
    if [[ "$confirm" == [yY] || "$confirm" == [yY][eE][sS] ]]; then
        echo -e "${B_GREEN}Starting afresh... ${RESET}"
        fn_stop_all_docker_containers
        rm -rf $DOCKER_HOME
        echo -e "${BB_RED}\nGo ahead and re-run the 'installer.sh' \n${RESET}"
        exit 0
    else
        echo -e "Okay! Come back when you're sure! "
        sleep 2
    fi
}

function fn_update_installation_status() {
    if [ -d "$DOCKER_HOME" ]; then
        if [ "$(fn_is_container_running caddy)" = true ] &&
            [ $(jq '.apps["layer4"].servers.tls_proxy.routes | length' $CADDY_CONFIG_FILE) ] >0; then
            # There is an existing setup, so present the limited menu
            EXISTING_SETUP=true
        else
            EXISTING_SETUP=false
        fi
    else
        # First run or a fresh installation, go ahead and copy the files
        fn_copy_files
        EXISTING_SETUP=false
    fi
}

function fn_deploy() {
    trap - INT
    local IS_DOCKER_INSTALLED=$(fn_check_for_pkg docker-ce)
    if [ "$IS_DOCKER_INSTALLED" = true ]; then
        # Do we have at least one domain name input?
        if [[ "${#SNI_DICT[@]}" -ne 0 ]]; then
            fn_typewriter "Firing up engines... 🚀" $B_RED
            fn_start_caddy $CADDY_CONFIG_FILE
            echo -e "${B_YELLOW}\nWaiting 10 seconds for TLS certificates to fully download...\n"
            sleep 10

            # Okay now check which ones are selected!
            if [ ! -z "${SNI_DICT[DNS_SUBDOMAIN]}" ]; then
                fn_start_blocky $BLOCKY_CONFIG_FILE
                sleep 1
            fi

            if [ ! -z "${SNI_DICT[VLESS_TCP_SUBDOMAIN]}" ] ||
                [ ! -z "${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}" ] ||
                [ ! -z "${SNI_DICT[VLESS_WS_SUBDOMAIN]}" ] ||
                [ ! -z "${SNI_DICT[TROJAN_H2_SUBDOMAIN]}" ] ||
                [ ! -z "${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}" ] ||
                [ ! -z "${SNI_DICT[TROJAN_WS_SUBDOMAIN]}" ] ||
                [ ! -z "${SNI_DICT[VMESS_WS_SUBDOMAIN]}" ]; then
                fn_start_xray $XRAY_CONFIG_FILE
                sleep 1
            fi

            if [ ! -z "${SNI_DICT[HYSTERIA_SUBDOMAIN]}" ]; then
                fn_start_hysteria $HYSTERIA_CONFIG_FILE $HYSTERIA_CLIENT_CONFIG_FILE
                sleep 1
            fi

            if [ ! -z "${SNI_DICT[MTPROTO_SUBDOMAIN]}" ]; then
                fn_start_mtprotopy $MTPROTOPY_CONFIG_FILE $MTPROTOPY_USERS_FILE
                sleep 1
            fi
        else
            echo -e "${B_RED}ERROR: No domains have been set for your proxies!${RESET}"
            sleep 1
        fi
    else
        echo -e "${B_RED}\nDocker is missing! Install it from the main menu.${RESET}"
        sleep 2
    fi
}

function fn_get_client_configs() {
    trap - INT

    # Print configs to screen
    fn_print_blocky_client_urls
    fn_print_xray_client_urls
    fn_print_hysteria_client_config
    fn_print_mtproto_client_urls

    # Create and notify about HOME/proxy-clients.zip
    zip -q $HOME/proxy-clients.zip $DOCKER_HOME/blocky/client/urls.txt $DOCKER_HOME/hysteria/client/hysteria.json $DOCKER_HOME/mtprotopy/client/share_urls.txt $DOCKER_HOME/xray/client/xray_share_urls.txt
    PUBLIC_IP=$(curl -s ipinfo.io/ip)
    echo -e "\n==============================================================="
    echo -e "You can also find client urls and configs inside ${GREEN}${HOME}/proxy-clients.zip${RESET}"
    echo -e "To download this file, you can use Filezilla to FTP or run the command below on your Linux computer :\n"
    echo -e "${B_CYAN}     scp ${USER}@${PUBLIC_IP}:${HOME}/proxy-clients.zip ~/Downloads/proxy-clients.zip${RESET}"

    if [ ! -z "${SNI_DICT[FALLBACK_DOMAIN]}" ]; then
        echo -e "\nPlace your static HTML files inside '${DOCKER_HOME}/caddy/www' to serve as your fallback (camouflage) website."
    fi

    echo -e "\n\n"
    fn_typewriter "RAGE, RAGE AGAINST THE DYING OF THE LIGHT..." $B_RED
    echo -e "\n"
    fn_typewriter "Women " $B_GREEN
    fn_typewriter "Life " $B_WHITE
    fn_typewriter "Freedom... ✌️" $B_RED
    echo -e "\n\n"
}

function fn_setup_server_submenu() {
    echo -ne "
*** Server Setup ***

${GREEN}1)${RESET} Update system packages
${GREEN}2)${RESET} Install Docker
${GREEN}3)${RESET} Setup Firewall
${RED}0)${RESET} Return to Main Menu

Choose an option: "
    read -r ans
    case $ans in
    3)
        clear
        fn_setup_firewall
        clear
        fn_setup_server_submenu
        ;;
    2)
        clear
        fn_install_docker
        clear
        fn_setup_server_submenu
        ;;
    1)
        clear
        fn_upgrade_os
        clear
        fn_setup_server_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_setup_server_submenu
        ;;
    esac
}
