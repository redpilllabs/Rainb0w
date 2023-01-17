#!/bin/bash

function fn_xray_add_vless_tcp() {
    xray_entry="{
            \"listen\": \"0.0.0.0\",
            \"port\": 3443,
            \"protocol\": \"vless\",
            \"settings\": {
                \"clients\": [
                    {
                        \"id\": \"${VLESS_TCP_UUID}\",
                        \"flow\": \"xtls-rprx-vision\"
                    }
                ],
                \"decryption\": \"none\"
            },
            \"streamSettings\": {
                \"network\": \"tcp\",
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${VLESS_TCP_SUBDOMAIN}/${VLESS_TCP_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${VLESS_TCP_SUBDOMAIN}/${VLESS_TCP_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${VLESS_TCP_SUBDOMAIN}\"
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
                                        \"xray:3443\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${VLESS_TCP_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${VLESS_TCP_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${VLESS_TCP_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_xray_add_vless_grpc() {
    xray_entry="{
            \"listen\": \"/dev/shm/Xray-VLESS-gRPC.socket,0666\",
            \"protocol\": \"vless\",
            \"settings\": {
                \"clients\": [
                    {
                        \"id\": \"${VLESS_GRPC_UUID}\"
                    }
                ],
                \"decryption\": \"none\"
            },
            \"streamSettings\": {
                \"network\": \"grpc\",
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${VLESS_GRPC_SUBDOMAIN}/${VLESS_GRPC_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${VLESS_GRPC_SUBDOMAIN}/${VLESS_GRPC_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${VLESS_GRPC_SUBDOMAIN}\"
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
                                        \"unix//dev/shm/Xray-VLESS-gRPC.socket\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${VLESS_GRPC_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${VLESS_GRPC_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${VLESS_GRPC_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_xray_add_vless_ws() {
    xray_entry="{
            \"listen\": \"/dev/shm/Xray-VLESS-WSS.socket,0666\",
            \"protocol\": \"vless\",
            \"settings\": {
                \"clients\": [
                    {
                        \"id\": \"${VLESS_WS_UUID}\"
                    }
                ],
                \"decryption\": \"none\"
            },
            \"streamSettings\": {
                \"network\": \"ws\",
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${VLESS_WS_SUBDOMAIN}/${VLESS_WS_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${VLESS_WS_SUBDOMAIN}/${VLESS_WS_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${VLESS_WS_SUBDOMAIN}\"
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
                                        \"unix//dev/shm/Xray-VLESS-WSS.socket\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${VLESS_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${VLESS_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${VLESS_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_xray_add_trojan_h2() {
    xray_entry="{
            \"listen\": \"0.0.0.0\",
            \"port\": 3444,
            \"protocol\": \"trojan\",
            \"settings\": {
                \"clients\": [
                    {
                        \"password\": \"${TROJAN_H2_PASSWORD}\"
                    }
                ]
            },
            \"streamSettings\": {
                \"network\": \"http\",
                \"httpSettings\": {
                    \"path\": \"/${TROJAN_H2_PATH}\",
                    \"host\": [
                        \"${TROJAN_H2_SUBDOMAIN}\"
                    ]
                },
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_H2_SUBDOMAIN}/${TROJAN_H2_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_H2_SUBDOMAIN}/${TROJAN_H2_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${TROJAN_H2_SUBDOMAIN}\"
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
                                        \"xray:3444\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${TROJAN_H2_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${TROJAN_H2_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${TROJAN_H2_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_xray_add_trojan_grpc() {
    xray_entry="{
            \"listen\": \"/dev/shm/Xray-Trojan-gRPC.socket,0666\",
            \"protocol\": \"trojan\",
            \"settings\": {
                \"clients\": [
                    {
                        \"password\": \"${TROJAN_GRPC_PASSWORD}\"
                    }
                ]
            },
            \"streamSettings\": {
                \"network\": \"grpc\",
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_GRPC_SUBDOMAIN}/${TROJAN_GRPC_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_GRPC_SUBDOMAIN}/${TROJAN_GRPC_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${TROJAN_GRPC_SUBDOMAIN}\"
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
                                        \"unix//dev/shm/Xray-Trojan-gRPC.socket\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${TROJAN_GRPC_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${TROJAN_GRPC_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${TROJAN_GRPC_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_xray_add_trojan_ws() {
    xray_entry="{
            \"listen\": \"0.0.0.0\",
            \"port\": 3445,
            \"protocol\": \"trojan\",
            \"settings\": {
                \"clients\": [
                    {
                        \"password\": \"${TROJAN_WS_PASSWORD}\"
                    }
                ]
            },
            \"streamSettings\": {
                \"network\": \"ws\",
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_WS_SUBDOMAIN}/${TROJAN_WS_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${TROJAN_WS_SUBDOMAIN}/${TROJAN_WS_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${TROJAN_WS_SUBDOMAIN}\"
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
                                        \"xray:3445\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${TROJAN_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${TROJAN_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${TROJAN_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_xray_add_vmess_ws() {
    xray_entry="{
            \"listen\": \"0.0.0.0\",
            \"port\": 3446,
            \"protocol\": \"vmess\",
            \"settings\": {
                \"clients\": [
                    {
                        \"id\": \"${VMESS_UUID}\",
                        \"security\": \"none\"
                    }
                ]
            },
            \"streamSettings\": {
                \"network\": \"ws\",
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${VMESS_WS_SUBDOMAIN}/${VMESS_WS_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${VMESS_WS_SUBDOMAIN}/${VMESS_WS_SUBDOMAIN}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds[.inbounds| length] |= . + ${xray_entry}" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${VMESS_WS_SUBDOMAIN}\"
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
                                        \"xray:3446\"
                                    ]
                                }
                            ]
                        }
                    ]
                }"
    tmp_caddy=$(jq ".apps.layer4.servers.tls_proxy.routes[.routes| length] |= . + ${caddy_entry}" $2)
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${VMESS_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${VMESS_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${VMESS_WS_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
}

function fn_configure_camouflage_website() {
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${CAMOUFLAGE_DOMAIN}\"]" $1)
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${CAMOUFLAGE_DOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.http.servers.web.routes[0].match[0].host += [\"${CAMOUFLAGE_DOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${CAMOUFLAGE_DOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_configure_xray() {
    if [ -v "${VLESS_TCP_SUBDOMAIN}" ]; then
        fn_xray_add_vless_tcp $1 $2
    fi
    if [ -v "${VLESS_GRPC_SUBDOMAIN}" ]; then
        fn_xray_add_vless_grpc $1 $2
    fi
    if [ -v "${VLESS_WS_SUBDOMAIN}" ]; then
        fn_xray_add_vless_ws $1 $2
    fi
    if [ -v "${TROJAN_H2_SUBDOMAIN}" ]; then
        fn_xray_add_trojan_h2 $1 $2
    fi
    if [ -v "${TROJAN_GRPC_SUBDOMAIN}" ]; then
        fn_xray_add_trojan_grpc $1 $2
    fi
    if [ -v "${TROJAN_WS_SUBDOMAIN}" ]; then
        fn_xray_add_trojan_ws $1 $2
    fi
    if [ -v "${VMESS_WS_SUBDOMAIN}" ]; then
        fn_xray_add_vmess_ws $1 $2
    fi
}

function fn_print_xray_client_urls() {
    if [ -d $DOCKER_DST_DIR/xray/client ]; then
        mkdir -p $DOCKER_DST_DIR/xray/client
    fi
    if [ -f $DOCKER_DST_DIR/xray/client/xray_share_urls.txt ]; then
        rm $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        touch $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${VLESS_TCP_SUBDOMAIN}" ]; then
        echo -e "\nvless://${VLESS_TCP_UUID}@${VLESS_TCP_SUBDOMAIN}:443?security=tls&encryption=none&alpn=h2,http/1.1&headerType=none&type=tcp&flow=xtls-rprx-vision-udp443&sni=${VLESS_TCP_SUBDOMAIN}#0xLem0nade+VLESS+TCP" | tee -a $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${VLESS_GRPC_SUBDOMAIN}" ]; then
        echo -e "\nvless://${VLESS_GRPC_UUID}@${VLESS_GRPC_SUBDOMAIN}:443?mode=gun&security=tls&encryption=none&alpn=h2,http/1.1&type=grpc&serviceName=&sni=${VLESS_GRPC_SUBDOMAIN}#0xLem0nade+VLESS+gRPC" | tee -a $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${VLESS_WS_SUBDOMAIN}" ]; then
        echo -e "\nvless://${VLESS_WS_UUID}@${VLESS_WS_SUBDOMAIN}:443?security=tls&encryption=none&alpn=h2,http/1.1&type=ws&sni=${VLESS_WS_SUBDOMAIN}#0xLem0nade+VLESS+WS" | tee -a $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${TROJAN_H2_SUBDOMAIN}" ]; then
        echo "\ntrojan://${TROJAN_H2_PASSWORD}@${TROJAN_H2_SUBDOMAIN}:443?path=${TROJAN_H2_PATH}&security=tls&alpn=h2,http/1.1&host=${TROJAN_H2_SUBDOMAIN}&type=http&sni=${TROJAN_H2_SUBDOMAIN}#0xLem0nade+Trojan+H2" | tee -a $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${TROJAN_GRPC_SUBDOMAIN}" ]; then
        echo -e "\ntrojan://${TROJAN_GRPC_PASSWORD}@${TROJAN_GRPC_SUBDOMAIN}:443?mode=gun&security=tls&alpn=h2,http/1.1&type=grpc&sni=${TROJAN_GRPC_SUBDOMAIN}#0xLem0nade+Trojan+gRPC" | tee -a $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${TROJAN_WS_SUBDOMAIN}" ]; then
        echo "\ntrojan://${TROJAN_WS_PASSWORD}@${TROJAN_WS_SUBDOMAIN}:443?security=tls&alpn=h2,http/1.1&type=ws&sni=${TROJAN_WS_SUBDOMAIN}#0xLem0nade+Trojan+WS" | tee -a $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${VMESS_WS_SUBDOMAIN}" ]; then
        vmess_config="{\"add\":\"${VMESS_WS_SUBDOMAIN}\",\"aid\":\"0\",\"alpn\":\"h2,http/1.1\",\"host\":\"${VMESS_WS_SUBDOMAIN}\",\"id\":\"${VMESS_WS_UUID}\",\"net\":\"ws\",\"path\":\"\",\"port\":\"443\",\"ps\":\"0xLem0nade Vmess WS\",\"scy\":\"none\",\"sni\":\"${VMESS_WS_SUBDOMAIN}\",\"tls\":\"tls\",\"type\":\"\",\"v\":\"2\"}"
        vmess_config=$(echo $vmess_config | base64 | tr -d '\n')
        echo "\nvmess://${vmess_config}" | tee -a $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
    fi

    # Print share URLs
    if [ -s $DOCKER_DST_DIR/xray/client/xray_share_urls.txt ]; then
        echo -e "${GREEN}########################################"
        echo -e "#           Xray/v2ray Proxies         #"
        echo -e "########################################${RESET}"
        cat $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
    fi
}

function fn_config_xray_submenu() {
    echo -ne "
*** Xray ***
${IBG_YELLOW}${BI_BLACK}BLANK ENTRIES WILL BE IGNORED.${RESET}

${GREEN}1)${RESET} Camouflage domain:                       ${CYAN}${DOMAIN}${RESET}
${GREEN}2)${RESET} VLESS [TCP]        [Direct]:             ${CYAN}${VLESS_TCP_SUBDOMAIN}${RESET}
${GREEN}3)${RESET} VLESS [gRPC]       [CDN Compatible]:     ${CYAN}${VLESS_GRPC_SUBDOMAIN}${RESET}
${GREEN}4)${RESET} VLESS [Websocket]  [CDN Compatible]:     ${CYAN}${VLESS_WS_SUBDOMAIN}${RESET}
${GREEN}5)${RESET} Trojan [HTTP2]     [Direct]:             ${CYAN}${TROJAN_H2_SUBDOMAIN}${RESET}
${GREEN}6)${RESET} Trojan [gRPC]      [CDN Compatible]:     ${CYAN}${TROJAN_GRPC_SUBDOMAIN}${RESET}
${GREEN}7)${RESET} Trojan [Websocket] [CDN Compatible]:     ${CYAN}${TROJAN_WS_SUBDOMAIN}${RESET}
${GREEN}8)${RESET} Vmess [Websocket]  [CDN Compatible]:     ${CYAN}${VMESS_WS_SUBDOMAIN}${RESET}
${RED}0)${RESET} Return to Main Menu
Choose an option: "
    read -r ans
    case $ans in
    8)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.example.com) for Vmess [Websocket] proxy" VMESS_WS_SUBDOMAIN
        fn_config_xray_submenu
        ;;
    7)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.example.com) for Trojan [Websocket] proxy" TROJAN_WS_SUBDOMAIN
        fn_config_xray_submenu
        ;;
    6)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.example.com) for Trojan [gRPC] proxy" TROJAN_GRPC_SUBDOMAIN
        fn_config_xray_submenu
        ;;
    5)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.example.com) for Trojan [HTTP2] proxy" TROJAN_H2_SUBDOMAIN
        fn_config_xray_submenu
        ;;
    4)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.example.com) for VLESS [WS] proxy" VLESS_WS_SUBDOMAIN
        fn_config_xray_submenu
        ;;
    3)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.example.com) for VLESS [gRPC] proxy" VLESS_GRPC_SUBDOMAIN
        fn_config_xray_submenu
        ;;
    2)
        clear
        fn_prompt_subdomain "Enter the full subdomain (e.g: xxx.example.com) for VLESS [TCP] proxy" VLESS_TCP_SUBDOMAIN
        fn_config_xray_submenu
        ;;
    1)
        clear
        fn_prompt_domain
        fn_config_xray_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_config_xray_submenu
        ;;
    esac
}
