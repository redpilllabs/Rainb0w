#!/bin/bash

source $PWD/scripts/colors.sh
source $PWD/scripts/config.sh
source $PWD/scripts/func.sh

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
        fi
    fi
fi

# Install pre-requisites
echo -e "${B_GREEN}Checking for requried packages${RESET}"
fn_install_required_packages
clear

# Check for existing setups
fn_update_installation_status
clear

function fn_print_header() {
    echo -ne "
    ##############################################################
    #                                                            #
    #  ${BB_GREEN}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣶⣿⠿⡿⡇${RESET}         Rainbow Proxy Installer    #
    #  ${BB_MAGENTA}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⠿⢛⡫⠭⠄⠒⠈⡉⡁${RESET}              Version: ${VERSION}          #
    #  ${BB_YELLOW}⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⢫⡡⠋⠁⣀⠤⣔⣖⠩⠭⡇${RESET}            Author: 0xLem0nade      #
    #  ${BB_CYAN}⠀⠀⠀⠀⠀⠀⠀⢠⣾⠏⡰⠋⢀⣔⡭⠚⢉⣡⣤⣤⣶⡇${RESET}                                    #
    #  ${BB_GREEN}⠀⠀⠀⠀⠀⠀⢰⣿⠏⡜⠁⡰⡽⠋⣠⣾⣿⣿⠿⠟⠛⠃${RESET}           twitter.com/0xLem0nade   #
    #  ${BB_YELLOW}⠀⠀⠀⠀⠀⢠⣿⡏⡼⠁⡰⡽⢁⣾⣿⡿⠋⠀⠀⠀⠀⠀${RESET}               t.me/Lem0net         #
    #  ${BB_RED}⠀⠀⠀⠀⠀⣾⣿⣰⠃⣰⢳⠁⣼⣿⡟⠀⠀⠀⠀⠀⠀⠀${RESET}          t.me/Lem0netDiscussion    #
    #  ${BB_MAGENTA}⠀⠀⠀⡠⠒⠙⠓⡯⠒⠉⠉⠉⠛⢿⠁⠀⠀⠀⠀⠀⠀⠀${RESET}                                    #
    #  ${BB_BLUE}⠀⠀⢰⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡄⠀⠀⠀⠀⠀⠀⠀${RESET}             #WomenLifeFreedom      #
    #  ${BB_BLUE}⢠⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠑⡄⠀⠀⠀⠀⠀${RESET}                                    #
    #  ${BB_CYAN}⢹⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⠀⠀⠀⠀⠀${RESET}                                    #
    #  ${BB_YELLOW}⠀⠑⠠⠤⠤⡀⠀⠀⠀⠀⢀⠤⢀⣀⠠⠜⠁⠀⠀⠀⠀⠀${RESET}                                    #
    #  ${BB_GREEN}⠀⠀⠀⠀⠀⠈⠐⠒⠒⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${RESET}                                    #
    ##############################################################
    "
}

function mainmenu_limited() {
    fn_print_header
    echo -ne "
${BB_YELLOW}<<< EXISTING SETUP DETECTED AT '${DOCKER_HOME}' >>>${RESET}
${B_CYAN}(i) To add/change proxies, you have to remove
the existing setup and re-run the installer!
Otherwise only the following options will be accessible.>>>${RESET}

*** Main Menu ***

${GREEN}1)${RESET} Setup Server
${GREEN}2)${RESET} Performance Tuning
${GREEN}3)${RESET} Access Controls
${GREEN}4)${RESET} Get Client Configs
${CYAN}5)${RESET} REMOVE EXISTING SETUP
${RED}0)${RESET} Exit

Choose an option: "
    read -r ans
    case $ans in
    5)
        clear
        fn_clear_existing_setup
        clear
        mainmenu
        ;;
    4)
        clear
        fn_get_client_configs
        exit 0
        ;;
    3)
        clear
        fn_ac_submenu
        clear
        mainmenu
        ;;
    2)
        clear
        fn_performance_submenu
        clear
        mainmenu
        ;;
    1)
        clear
        fn_setup_server_submenu
        clear
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

function mainmenu_new() {
    fn_print_header
    echo -ne "
*** Main Menu ***

${GREEN}1)${RESET} Setup Server
${GREEN}2)${RESET} Performance Settings
${GREEN}3)${RESET} Access Controls

${GREEN}5)${RESET} Xray/v2ray
${GREEN}6)${RESET} Hysteria
${GREEN}7)${RESET} MTProto (Telegram)
${GREEN}8)${RESET} Deploy Proxies
${GREEN}9)${RESET} Get Client Configs
${RED}0)${RESET} Exit

Choose an option: "
    read -r ans
    case $ans in
    9)
        clear
        fn_get_client_configs
        exit 0
        ;;
    8)
        clear
        fn_deploy
        clear
        mainmenu
        ;;
    7)
        clear
        fn_mtproto_submenu
        clear
        mainmenu
        ;;
    6)
        clear
        fn_hysteria_submenu
        clear
        mainmenu
        ;;
    5)
        clear
        fn_xray_submenu
        clear
        mainmenu
        ;;
    # 4)
    #     clear
    #     fn_dns_submenu
    #     clear
    #     mainmenu
    #     ;;
    3)
        clear
        fn_ac_submenu
        clear
        mainmenu
        ;;
    2)
        clear
        fn_performance_submenu
        clear
        mainmenu
        ;;
    1)
        clear
        fn_setup_server_submenu
        clear
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

function mainmenu() {
    if [ "$EXISTING_SETUP" = false ]; then
        mainmenu_new
    else
        mainmenu_limited
    fi
}

mainmenu
