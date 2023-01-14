#!/bin/bash

source $PWD/scripts/colors.sh
source $PWD/scripts/config.sh
source $PWD/scripts/func.sh

trap '' INT

# # OS check
# if ! [[ "$DISTRO" =~ "Ubuntu" || "$DISTRO" =~ "Debian" ]]; then
#     echo "$DISTRO"
#     echo -e "${B_RED}This installer only supports Debian and Ubuntu OS!${RESET}"
#     exit 0
# else
#     # Version check
#     if [[ "$DISTRO" =~ "Ubuntu" ]]; then
#         if [ ! "$DISTRO_VERSION" == "20.04" ] && [ ! "$DISTRO_VERSION" == "22.04" ]; then
#             echo "Your version of Ubuntu is not supported! Only 20.04 and 22.04 versions are supported."
#             exit 0
#         fi
#     elif [[ "$DISTRO" =~ "Debian GNU/Linux" ]]; then
#         if [ ! "$DISTRO_VERSION" == "11" ]; then
#             echo "Your version of Debian is not supported! Minimum required version is 11"
#             exit 0
#         fi
#     fi
# fi

# Header
echo -e "####################################################################"
echo -e "#                                                                  #"
echo -e "#                                                                  #"
echo -e "#                Dockerized TLS Proxy Installer                    #"
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

function fn_setup_server_submenu() {
    echo -ne "
Choose from options below to proceed:

${GREEN}1)${RESET} Update packages
${GREEN}2)${RESET} Install Docker
${GREEN}3)${RESET} Setup Firewall           ${MAGENTA}[Security]${RESET} (Optional)
${GREEN}4)${RESET} Block outbound to Iran   ${MAGENTA}[Security]${RESET} (Optional)
${GREEN}5)${RESET} Install ZRAM             ${CYAN}[Performance]${RESET} (Optional)
${GREEN}6)${RESET} Tune Network Stack       ${CYAN}[Performance]${RESET} (Optional)
${RED}0)${RESET} Return to Main Menu
Choose an option: "
    read -r ans
    case $ans in
    6)
        clear
        fn_tune_system
        fn_setup_server_submenu
        ;;
    5)
        clear
        fn_setup_zram
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
${GREEN}2)${RESET} Configure Xray [VLESS,Vmess,Trojan]
${GREEN}3)${RESET} Configure Hysteria
${GREEN}4)${RESET} Configure MTProto
${GREEN}5)${RESET} Start Proxies
${GREEN}6)${RESET} Get Client Configs
${RED}0)${RESET} Exit
Choose an option: "
    read -r ans
    case $ans in
    6)
        clear
        fn_get_client_configs
        fn_exit
        ;;
    5)
        clear
        fn_start_proxies
        mainmenu
        ;;
    4)
        clear
        fn_config_mtproto_submenu
        mainmenu
        ;;
    3)
        clear
        fn_config_hysteria_submenu
        mainmenu
        ;;
    2)
        clear
        fn_config_xray_submenu
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
