#!/bin/bash

function fn_configure_mtproto_users() {
    # This is a TOML file so we revert to sed
    sed -i -e "s/\<TG_SECRET\>/$TG_SECRET/" $1
}

function fn_configure_mtproto() {
    # This is a TOML file so we revert to sed
    sed -i -e "s/\<MTPROTO_SUBDOMAIN\>/${SNI_DICT[MTPROTO_SUBDOMAIN]}/g" $1
}

function fn_start_mtprotopy() {
    fn_configure_mtproto $1
    fn_configure_mtproto_users $2
    fn_start_docker_container mtprotopy
}

function fn_print_mtproto_client_urls() {
    if [ -s "$DOCKER_HOME/mtprotopy/client/share_urls.txt" ]; then
        echo -e "${B_MAGENTA}\n########################################"
        echo -e "#           Telegram Proxies           #"
        echo -e "########################################${RESET}"
        cat $DOCKER_HOME/mtprotopy/client/share_urls.txt
    fi
}

function fn_mtproto_submenu() {
    echo -ne "
*** Telegram MTProto ***

${GREEN}1)${RESET} Domain Address:              ${B_GREEN}${SNI_DICT[MTPROTO_SUBDOMAIN]}${RESET}
${GREEN}-)${RESET} Secret (AUTO GENERATED):     ${B_GREEN}${TG_SECRET}${RESET}
${RED}0)${RESET} Return to Main Menu

Choose any option: "
    read -r ans
    case $ans in
    1)
        clear
        fn_prompt_domain "MTProto proxy" MTPROTO_SUBDOMAIN
        clear
        fn_mtproto_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_mtproto_submenu
        ;;
    esac
}
