#!/bin/bash

source scripts/colors.sh
source scripts/config.sh
source scripts/func.sh

# Exit immediately if a pipeline fails
set -e

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
        fi
    fi
fi

# Header
echo -e "####################################################################"
echo -e "#                                                                  #"
echo -e "#                                                                  #"
echo -e "#                Dockerized Proxy Installer                        #"
echo -e "#                      Version: ${VERSION}                                #"
echo -e "#                      Author: 0xLem0nade                          #"
echo -e "#                  Twitter: twitter.com/0xLem0nade                 #"
echo -e "#                  Telegram Channel: t.me/Lem0net                  #"
echo -e "#               Telegram Group: t.me/Lem0netDiscussion             #"
echo -e "#                                                                  #"
echo -e "#                                                                  #"
echo -e "####################################################################"
echo ""
echo -e "${B_RED}\n*** Make sure you have gone through the README over the GitHub repo before proceeding! ***\n${RESET}"
echo -e "${YELLOW}NOTE: You will need the following requirements before proceeding:${RESET}"
echo -e "${CYAN}- A free Cloudflare account"
echo -e "- A free/paid domain name added to your Cloudflare account"
echo -e "- Subdomains created for each proxy destination \n${RESET}"

function fn_exit() {
    echo "Quitting!"
    exit 0
}
function fn_fail() {
    echo "Wrong option!"
}

function fn_config_proxy_submenu() {
    echo -ne "
Choose any option to add or edit the entry,
Entries with * are required!
${IBG_YELLOW}${BI_BLACK}BLANK ENTRIES WILL BE IGNORED.${RESET}

${GREEN}1)*${RESET} Website/Blog domain:        ${CYAN}${DOMAIN}${RESET}
${GREEN}3)${RESET} VLESS XTLS:          ${CYAN}${XTLS_SUBDOMAIN}${RESET}
${GREEN}4)${RESET} Trojan HTTP2:        ${CYAN}${TROJAN_H2_SUBDOMAIN}${RESET}
${GREEN}5)${RESET} Trojan gRPC:         ${CYAN}${TROJAN_GRPC_SUBDOMAIN}${RESET}
${GREEN}6)${RESET} Trojan Websocket:    ${CYAN}${TROJAN_WS_SUBDOMAIN}${RESET}
${GREEN}7)${RESET} VMess Websocket:     ${CYAN}${VMESS_WS_SUBDOMAIN}${RESET}
${GREEN}8)${RESET} Hysteria UDP:        ${CYAN}${HYSTERIA_SUBDOMAIN}${RESET}
${GREEN}9)${RESET} MTProto (Telegram):  ${CYAN}${MTPROTO_SUBDOMAIN}${RESET}
${RED}0)${RESET} Return to Main Menu
Choose an option: "
    read -r ans
    case $ans in
    9)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.${DOMAIN}) for Telegram MTProto proxy" MTPROTO_SUBDOMAIN
        fn_config_proxy_submenu
        ;;
    8)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.${DOMAIN}) for Hysteria proxy" HYSTERIA_SUBDOMAIN
        fn_config_proxy_submenu
        ;;
    7)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.${DOMAIN}) for VMess Websocket proxy" VMESS_WS_SUBDOMAIN
        fn_config_proxy_submenu
        ;;
    6)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.${DOMAIN}) for Trojan Websocket proxy" TROJAN_WS_SUBDOMAIN
        fn_config_proxy_submenu
        ;;
    5)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.${DOMAIN}) for Trojan gRPC proxy" TROJAN_GRPC_SUBDOMAIN
        fn_config_proxy_submenu
        ;;
    4)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.${DOMAIN}) for Trojan HTTP proxy" TROJAN_H2_SUBDOMAIN
        fn_config_proxy_submenu
        ;;
    3)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.${DOMAIN}) for XTLS proxy" XTLS_SUBDOMAIN
        fn_config_proxy_submenu
        ;;
    2)
        clear
        fn_prompt_email
        fn_config_proxy_submenu
        ;;
    1)
        clear
        fn_prompt_domain
        fn_config_proxy_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_config_proxy_submenu
        ;;
    esac
}

function fn_setup_server_submenu() {
    echo -ne "
Choose from options below to proceed:

${GREEN}1)${RESET} Update packages
${GREEN}2)${RESET} Install Docker
${GREEN}3)${RESET} Setup Firewall           ${MAGENTA}[Security]${RESET} (Optional)
${GREEN}4)${RESET} Block outbound to Iran   ${MAGENTA}[Security]${RESET} (Optional)
${GREEN}5)${RESET} Harden SSH Logins        ${MAGENTA}[Security]${RESET} (Optional)
${GREEN}6)${RESET} Install ZRAM             ${CYAN}[Performance]${RESET} (Optional)
${GREEN}7)${RESET} Tune Network Stack       ${CYAN}[Performance]${RESET} (Optional)
${RED}0)${RESET} Return to Main Menu
Choose an option: "
    read -r ans
    case $ans in
    7)
        clear
        fn_tune_system
        fn_setup_server_submenu
        ;;
    6)
        clear
        fn_setup_zram
        fn_setup_server_submenu
        ;;
    5)
        clear
        fn_harden_ssh_security
        fn_setup_server_submenu
        ;;
    4)
        clear
        fn_block_outbound_connections_to_iran
        fn_enable_xtgeoip_cronjob
        fn_setup_server_submenu
        ;;
    3)
        clear
        fn_setup_firewall
        fn_setup_server_submenu
        ;;
    2)
        clear
        fn_install_docker
        fn_setup_server_submenu
        ;;
    1)
        clear
        fn_upgrade_os
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

function mainmenu() {
    echo -ne "
Choose from options below to proceed:

${GREEN}1)${RESET} Setup Server
${GREEN}2)${RESET} Configure Proxies
${GREEN}3)${RESET} Start Proxies
${GREEN}4)${RESET} Get Client Configs
${RED}0)${RESET} Exit
Choose an option: "
    read -r ans
    case $ans in
    4)
        clear
        fn_get_client_configs
        mainmenu
        ;;
    3)
        clear
        fn_start_proxies
        mainmenu
        ;;
    2)
        clear
        fn_config_proxy_submenu
        mainmenu
        ;;
    1)
        clear
        fn_setup_server_submenu
        mainmenu
        ;;
    0)
        fn_exit
        ;;
    *)
        fn_fail
        clear
        mainmenu
        ;;
    esac
}

mainmenu
