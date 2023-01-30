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
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[VLESS_TCP_SUBDOMAIN]}/${SNI_DICT[VLESS_TCP_SUBDOMAIN]}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[VLESS_TCP_SUBDOMAIN]}/${SNI_DICT[VLESS_TCP_SUBDOMAIN]}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds +=  [${xray_entry}]" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
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
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}/${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}/${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds +=  [${xray_entry}]" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
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
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[VLESS_WS_SUBDOMAIN]}/${SNI_DICT[VLESS_WS_SUBDOMAIN]}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[VLESS_WS_SUBDOMAIN]}/${SNI_DICT[VLESS_WS_SUBDOMAIN]}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds +=  [${xray_entry}]" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
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
                        \"${SNI_DICT[TROJAN_H2_SUBDOMAIN]}\"
                    ]
                },
                \"security\": \"tls\",
                \"tlsSettings\": {
                    \"rejectUnknownSni\": true,
                    \"certificates\": [
                        {
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[TROJAN_H2_SUBDOMAIN]}/${SNI_DICT[TROJAN_H2_SUBDOMAIN]}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[TROJAN_H2_SUBDOMAIN]}/${SNI_DICT[TROJAN_H2_SUBDOMAIN]}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds +=  [${xray_entry}]" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
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
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}/${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}/${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds +=  [${xray_entry}]" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
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
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[TROJAN_WS_SUBDOMAIN]}/${SNI_DICT[TROJAN_WS_SUBDOMAIN]}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[TROJAN_WS_SUBDOMAIN]}/${SNI_DICT[TROJAN_WS_SUBDOMAIN]}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds +=  [${xray_entry}]" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
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
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[VMESS_WS_SUBDOMAIN]}/${SNI_DICT[VMESS_WS_SUBDOMAIN]}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${SNI_DICT[VMESS_WS_SUBDOMAIN]}/${SNI_DICT[VMESS_WS_SUBDOMAIN]}.key\"
                        }
                    ]
                }
            }
        }"
    jq ".inbounds +=  [${xray_entry}]" $1 >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_logrotate_xray() {
    if [ ! -f "/etc/logrotate.d/xray" ]; then
        sudo touch /etc/logrotate.d/xray
        sudo sh -c 'echo "/var/log/xray.log
{
	size 20M
    rotate 5
    copytruncate
	missingok
	notifempty
	compress
	delaycompress
}" > /etc/logrotate.d/xray'
    fi
}

function fn_configure_xray() {
    if [ ! -z "${SNI_DICT[VLESS_TCP_SUBDOMAIN]}" ]; then
        fn_xray_add_vless_tcp $1
    fi
    if [ ! -z "${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}" ]; then
        fn_xray_add_vless_grpc $1
    fi
    if [ ! -z "${SNI_DICT[VLESS_WS_SUBDOMAIN]}" ]; then
        fn_xray_add_vless_ws $1
    fi
    if [ ! -z "${SNI_DICT[TROJAN_H2_SUBDOMAIN]}" ]; then
        fn_xray_add_trojan_h2 $1
    fi
    if [ ! -z "${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}" ]; then
        fn_xray_add_trojan_grpc $1
    fi
    if [ ! -z "${SNI_DICT[TROJAN_WS_SUBDOMAIN]}" ]; then
        fn_xray_add_trojan_ws $1
    fi
    if [ ! -z "${SNI_DICT[VMESS_WS_SUBDOMAIN]}" ]; then
        fn_xray_add_vmess_ws $1
    fi
}

function fn_configure_xray_client() {
    if [ ! -d $DOCKER_HOME/xray/client ]; then
        mkdir -p $DOCKER_HOME/xray/client
    fi
    if [ -f $DOCKER_HOME/xray/client/xray_share_urls.txt ]; then
        rm $DOCKER_HOME/xray/client/xray_share_urls.txt
        touch $DOCKER_HOME/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${SNI_DICT[VLESS_TCP_SUBDOMAIN]}" ]; then
        echo -e "\nvless://${VLESS_TCP_UUID}@${SNI_DICT[VLESS_TCP_SUBDOMAIN]}:443?security=tls&encryption=none&alpn=h2,http/1.1&headerType=none&type=tcp&flow=xtls-rprx-vision-udp443&sni=${SNI_DICT[VLESS_TCP_SUBDOMAIN]}#0xLem0nade+VLESS+TCP" >$DOCKER_HOME/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}" ]; then
        echo -e "\nvless://${VLESS_GRPC_UUID}@${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}:443?mode=gun&security=tls&encryption=none&alpn=h2,http/1.1&type=grpc&serviceName=&sni=${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}#0xLem0nade+VLESS+gRPC" >>$DOCKER_HOME/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${SNI_DICT[VLESS_WS_SUBDOMAIN]}" ]; then
        echo -e "\nvless://${VLESS_WS_UUID}@${SNI_DICT[VLESS_WS_SUBDOMAIN]}:443?security=tls&encryption=none&alpn=h2,http/1.1&type=ws&sni=${SNI_DICT[VLESS_WS_SUBDOMAIN]}#0xLem0nade+VLESS+WS" >>$DOCKER_HOME/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${SNI_DICT[TROJAN_H2_SUBDOMAIN]}" ]; then
        echo -e "\ntrojan://${TROJAN_H2_PASSWORD}@${SNI_DICT[TROJAN_H2_SUBDOMAIN]}:443?path=${TROJAN_H2_PATH}&security=tls&alpn=h2,http/1.1&host=${SNI_DICT[TROJAN_H2_SUBDOMAIN]}&type=http&sni=${SNI_DICT[TROJAN_H2_SUBDOMAIN]}#0xLem0nade+Trojan+H2" >>$DOCKER_HOME/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}" ]; then
        echo -e "\ntrojan://${TROJAN_GRPC_PASSWORD}@${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}:443?mode=gun&security=tls&alpn=h2,http/1.1&type=grpc&sni=${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}#0xLem0nade+Trojan+gRPC" >>$DOCKER_HOME/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${SNI_DICT[TROJAN_WS_SUBDOMAIN]}" ]; then
        echo -e "\ntrojan://${TROJAN_WS_PASSWORD}@${SNI_DICT[TROJAN_WS_SUBDOMAIN]}:443?security=tls&alpn=h2,http/1.1&type=ws&sni=${SNI_DICT[TROJAN_WS_SUBDOMAIN]}#0xLem0nade+Trojan+WS" >>$DOCKER_HOME/xray/client/xray_share_urls.txt
    fi
    if [ ! -z "${SNI_DICT[VMESS_WS_SUBDOMAIN]}" ]; then
        vmess_config="{\"add\":\"${SNI_DICT[VMESS_WS_SUBDOMAIN]}\",\"aid\":\"0\",\"alpn\":\"h2,http/1.1\",\"host\":\"${SNI_DICT[VMESS_WS_SUBDOMAIN]}\",\"id\":\"${VMESS_WS_UUID}\",\"net\":\"ws\",\"path\":\"\",\"port\":\"443\",\"ps\":\"0xLem0nade Vmess WS\",\"scy\":\"none\",\"sni\":\"${SNI_DICT[VMESS_WS_SUBDOMAIN]}\",\"tls\":\"tls\",\"type\":\"\",\"v\":\"2\"}"
        vmess_config=$(echo $vmess_config | base64 | tr -d '\n')
        echo -e "\nvmess://${vmess_config}" >>$DOCKER_HOME/xray/client/xray_share_urls.txt
    fi
}

function fn_start_xray() {
    fn_logrotate_xray
    fn_configure_xray $1
    fn_start_docker_container xray
    fn_configure_xray_client
}

function fn_print_xray_client_urls() {
    # Print share URLs
    if [ -s "$DOCKER_HOME/xray/client/xray_share_urls.txt" ]; then
        echo -e "${B_MAGENTA}\n########################################"
        echo -e "#           Xray/v2ray Proxies         #"
        echo -e "########################################${RESET}"
        cat $DOCKER_HOME/xray/client/xray_share_urls.txt
        echo -e ""
        echo -e "${B_YELLOW}NOTE: Remember to set the 'uTLS Fingerprint' in your client"
        echo -e "sharing urls do not include this setting by default!${RESET}"
    fi
}

function fn_xray_submenu() {
    echo -ne "
*** Xray ***
${IBG_YELLOW}${BI_BLACK}BLANK ENTRIES WILL BE IGNORED.${RESET}

${GREEN}1)${RESET} VLESS [TCP]        [Direct]:             ${B_GREEN}${SNI_DICT[VLESS_TCP_SUBDOMAIN]}${RESET}
${GREEN}2)${RESET} VLESS [gRPC]       [CDN Compatible]:     ${B_GREEN}${SNI_DICT[VLESS_GRPC_SUBDOMAIN]}${RESET}
${GREEN}3)${RESET} VLESS [Websocket]  [CDN Compatible]:     ${B_GREEN}${SNI_DICT[VLESS_WS_SUBDOMAIN]}${RESET}
${GREEN}4)${RESET} Trojan [HTTP2]     [Direct]:             ${B_GREEN}${SNI_DICT[TROJAN_H2_SUBDOMAIN]}${RESET}
${GREEN}5)${RESET} Trojan [gRPC]      [CDN Compatible]:     ${B_GREEN}${SNI_DICT[TROJAN_GRPC_SUBDOMAIN]}${RESET}
${GREEN}6)${RESET} Trojan [Websocket] [CDN Compatible]:     ${B_GREEN}${SNI_DICT[TROJAN_WS_SUBDOMAIN]}${RESET}
${GREEN}7)${RESET} Vmess [Websocket]  [CDN Compatible]:     ${B_GREEN}${SNI_DICT[VMESS_WS_SUBDOMAIN]}${RESET}
${GREEN}8)${RESET} Fallback (camouflage) domain             ${B_GREEN}${SNI_DICT[FALLBACK_DOMAIN]}${RESET}
${RED}0)${RESET} Return to Main Menu

Choose an option: "
    read -r ans
    case $ans in
    8)
        clear
        fn_prompt_domain "Fallback camouflage website" FALLBACK_DOMAIN
        clear
        fn_xray_submenu
        ;;
    7)
        clear
        fn_prompt_domain "Vmess [Websocket]" VMESS_WS_SUBDOMAIN
        clear
        fn_xray_submenu
        ;;
    6)
        clear
        fn_prompt_domain "Trojan [Websocket]" TROJAN_WS_SUBDOMAIN
        clear
        fn_xray_submenu
        ;;
    5)
        clear
        fn_prompt_domain "Trojan [gRPC]" TROJAN_GRPC_SUBDOMAIN
        clear
        fn_xray_submenu
        ;;
    4)
        clear
        fn_prompt_domain "Trojan [HTTP2]" TROJAN_H2_SUBDOMAIN
        clear
        fn_xray_submenu
        ;;
    3)
        clear
        fn_prompt_domain "VLESS [WS]" VLESS_WS_SUBDOMAIN
        clear
        fn_xray_submenu
        ;;
    2)
        clear
        fn_prompt_domain "VLESS [gRPC]" VLESS_GRPC_SUBDOMAIN
        clear
        fn_xray_submenu
        ;;
    1)
        clear
        fn_prompt_domain "VLESS [TCP]" VLESS_TCP_SUBDOMAIN
        clear
        fn_xray_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_xray_submenu
        ;;
    esac
}
