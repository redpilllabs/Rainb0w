#!/bin/bash

function fn_configure_hysteria() {
    tmp_hysteria=$(jq ".obfs = \"${HYSTERIA_OBFS}\"" $1)
    tmp_hysteria=$(jq ".cert = \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${HYSTERIA_SUBDOMAIN}/${HYSTERIA_SUBDOMAIN}.crt\"" <<<"$tmp_hysteria")
    jq ".key = \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${HYSTERIA_SUBDOMAIN}/${HYSTERIA_SUBDOMAIN}.key\"" <<<"$tmp_hysteria" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_configure_hysteria_client() {
    tmp_hysteria=$(jq ".obfs = \"${HYSTERIA_OBFS}\"" $1)
    tmp_hysteria=$(jq ".server = \"${HYSTERIA_SUBDOMAIN}:554\"" <<<"$tmp_hysteria")
    jq ".server_name = \"${HYSTERIA_SUBDOMAIN}\"" <<<"$tmp_hysteria" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_print_hysteria_client_config() {
    if [ ! -z "${HYSTERIA_SUBDOMAIN}" ]; then
        echo -e "${GREEN}########################################"
        echo -e "#           Hysteria config            #"
        echo -e "########################################${RESET}"
        cat $DOCKER_DST_DIR/hysteria/client/hysteria.json
    fi
}

function fn_config_hysteria_submenu() {
    echo -ne "
*** Hysteria [UDP] ***

${GREEN}1)${RESET} Domain Address:          ${CYAN}${HYSTERIA_SUBDOMAIN}${RESET}
${GREEN}-)${RESET} Obfs (AUTO GENERATED):   ${CYAN}${HYSTERIA_OBFS}${RESET}
${RED}0)${RESET} Return to Main Menu
Choose any option: "
    read -r ans
    case $ans in
    1)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.example.com) for Hysteria [UDP] proxy" HYSTERIA_SUBDOMAIN
        fn_config_hysteria_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_config_hysteria_submenu
        ;;
    esac
}
