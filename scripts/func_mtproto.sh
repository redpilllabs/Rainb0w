#!/bin/bash

function fn_configure_mtproto_users() {
    sed -i -e "s/\<TG_SECRET\>/$TG_SECRET/" $1
}

function fn_configure_mtproto() {
    # This is a TOML file so we revert to sed
    sed -i -e "s/\<MTPROTO_SUBDOMAIN\>/${SNI_DICT[MTPROTO_SUBDOMAIN]}/g" $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${SNI_DICT[MTPROTO_SUBDOMAIN]}\"
                                ]
                            }
                        }
                    ],
                    \"handle\": [
                        {
                            \"handler\": \"proxy\",
                            \"upstreams\": [
                                {
                                    \"dial\": [
                                        \"mtproto:5443\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${SNI_DICT[MTPROTO_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${SNI_DICT[MTPROTO_SUBDOMAIN]}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${SNI_DICT[MTPROTO_SUBDOMAIN]}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_print_mtproto_client_urls() {
    if [ ! -z "${SNI_DICT[MTPROTO_SUBDOMAIN]}" ]; then
        echo -e "${GREEN}########################################"
        echo -e "#           Telegram Proxies           #"
        echo -e "########################################${RESET}"
        cat $DOCKER_DST_DIR/mtproto/client/share_urls.txt
    fi
}

function fn_config_mtproto_submenu() {
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
        fn_config_mtproto_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_config_mtproto_submenu
        ;;
    esac
}
