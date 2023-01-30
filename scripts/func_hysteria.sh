#!/bin/bash

function fn_configure_hysteria() {
    tmp_hysteria=$(jq ".listen = \":${HYSTERIA_PORT}\"" $1)
    tmp_hysteria=$(jq ".obfs = \"${HYSTERIA_OBFS}\"" <<<"$tmp_hysteria")
    tmp_hysteria=$(jq ".cert = \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[HYSTERIA_SUBDOMAIN]}/${SNI_DICT[HYSTERIA_SUBDOMAIN]}.crt\"" <<<"$tmp_hysteria")
    jq ".key = \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[HYSTERIA_SUBDOMAIN]}/${SNI_DICT[HYSTERIA_SUBDOMAIN]}.key\"" <<<"$tmp_hysteria" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_configure_hysteria_client() {
    tmp_hysteria=$(jq ".obfs = \"${HYSTERIA_OBFS}\"" $1)
    tmp_hysteria=$(jq ".server = \"${SNI_DICT[HYSTERIA_SUBDOMAIN]}:${HYSTERIA_PORT}\"" <<<"$tmp_hysteria")
    jq ".server_name = \"${SNI_DICT[HYSTERIA_SUBDOMAIN]}\"" <<<"$tmp_hysteria" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_add_firewall_rules() {
    echo -e "${GREEN}Allowing Hysteria UDP port ${HYSTERIA_PORT} traffic in the firewall ${RESET}"
    sudo iptables -A INPUT -p udp --dport $HYSTERIA_PORT -m comment --comment "Allow Hysteria" -j ACCEPT
    sudo ip6tables -A INPUT -p udp --dport $HYSTERIA_PORT -m comment --comment "Allow Hysteria" -j ACCEPT
}

function fn_start_hysteria() {
    fn_add_firewall_rules
    fn_configure_hysteria $1
    fn_configure_hysteria_client $2
    fn_start_docker_container hysteria
}

function fn_print_hysteria_client_config() {
    if [ ! "$(cat $DOCKER_HOME/hysteria/client/hysteria.json | grep -e HYSTERIA_SUBDOMAIN)" ]; then
        echo -e "${B_MAGENTA}\n########################################"
        echo -e "#           Hysteria config            #"
        echo -e "########################################${RESET}"
        echo -e "${B_YELLOW}Server:     ${B_GREEN}${SNI_DICT[HYSTERIA_SUBDOMAIN]}${RESET}"
        echo -e "${B_YELLOW}Port:       ${B_GREEN}${HYSTERIA_PORT}${RESET}"
        echo -e "${B_YELLOW}Password:   ${B_GREEN}${HYSTERIA_OBFS}${RESET}"
        echo -e "${B_YELLOW}Protocol:   ${B_GREEN}UDP${RESET}"
        echo -e ""
        echo -e "${B_YELLOW}NOTE: Remember to set the Max Upload and Max Download speeds in your client"
        echo -e "according to your connection speed, it's necessary for an optimal performance.${RESET}"
    fi
}

function fn_hysteria_submenu() {
    echo -ne "
*** Hysteria [UDP] ***

${GREEN}1)${RESET} Domain Address:              ${B_GREEN}${SNI_DICT[HYSTERIA_SUBDOMAIN]}${RESET}
${GREEN}-)${RESET} Port (AUTO GENERATED):       ${B_GREEN}${HYSTERIA_PORT}${RESET}
${GREEN}-)${RESET} Password (AUTO GENERATED):   ${B_GREEN}${HYSTERIA_OBFS}${RESET}
${RED}0)${RESET} Return to Main Menu

Choose any option: "
    read -r ans
    case $ans in
    1)
        clear
        fn_prompt_domain "Hysteria [UDP]" HYSTERIA_SUBDOMAIN
        clear
        fn_hysteria_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_hysteria_submenu
        ;;
    esac
}
