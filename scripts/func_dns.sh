#!/bin/bash

function fn_configure_blocky() {
    yq -i '.httpPort = 0' $1
    yq -i '.httpsPort = 443' $1
    yq -i '.tlsPort = 853' $1
    yq -i '.minTlsServeVersion = 1.3' $1
    yq -i ".certFile = \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[DNS_SUBDOMAIN]}/${SNI_DICT[DNS_SUBDOMAIN]}.crt\"" $1
    yq -i ".keyFile = \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[DNS_SUBDOMAIN]}/${SNI_DICT[DNS_SUBDOMAIN]}.key\"" $1
}

function fn_configure_blocky_client() {
    if [ ! -d $DOCKER_HOME/blocky/client ]; then
        mkdir -p $DOCKER_HOME/blocky/client
    fi
    if [ -f $DOCKER_HOME/blocky/client/urls.txt ]; then
        rm $DOCKER_HOME/blocky/client/urls.txt
        touch $DOCKER_HOME/blocky/client/urls.txt
    fi
    echo -e "\nDNS-over-HTTPS:     https://${SNI_DICT[DNS_SUBDOMAIN]}/dns-query" >$DOCKER_HOME/blocky/client/urls.txt
    echo -e "DNS-over-TLS:       tls://${SNI_DICT[DNS_SUBDOMAIN]}" >>$DOCKER_HOME/blocky/client/urls.txt
}

function fn_start_blocky() {
    fn_configure_blocky $1
    fn_start_docker_container blocky
    fn_configure_blocky_client
}

function fn_print_blocky_client_urls() {
    # Print share URLs
    if [ -s "$DOCKER_HOME/blocky/client/urls.txt" ]; then
        echo -e "${B_MAGENTA}\n########################################"
        echo -e "#         DNS over HTTPS/TLS           #"
        echo -e "########################################${RESET}"
        cat $DOCKER_HOME/blocky/client/urls.txt
    fi
}

function fn_dns_submenu() {
    echo -ne "
*** Encrypted DNS ***

${GREEN}1)${RESET} DNS over HTTPS/TLS (Sub)Domain:     ${B_GREEN}${SNI_DICT[DNS_SUBDOMAIN]}${RESET}
${RED}0)${RESET} Return to Main Menu

Choose any option: "
    read -r ans
    case $ans in
    1)
        clear
        fn_prompt_domain "DNS over HTTPS/TLS" DNS_SUBDOMAIN
        clear
        fn_dns_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_dns_submenu
        ;;
    esac
}
