#!/bin/bash

function fn_upgrade_os() {
    # Update OS
    echo -e " ${B_GREEN}### Updating the operating system \n ${RESET}"
    sudo apt update
    sudo apt upgrade -y
}

function fn_tune_system() {
    echo -e "${B_GREEN}### Tuning system network stack for best performance${RESET}"
    echo "net.core.rmem_max=4000000" | tee -a /etc/sysctl.d/99-sysctl.conf >/dev/null
    echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.d/99-sysctl.conf >/dev/null
    echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.d/99-sysctl.conf >/dev/null
    echo "net.ipv4.tcp_slow_start_after_idle=0" | tee -a /etc/sysctl.d/99-sysctl.conf >/dev/null
    sudo sysctl -p /etc/sysctl.d/99-sysctl.conf
    echo -e "${B_GREEN}Done!${RESET}"
    sleep 1
}

function fn_setup_zram() {
    echo -e "${B_GREEN}### Installing required packages for ZRam swap \n  ${RESET}"
    sudo apt install -y zram-tools linux-modules-extra-$(uname -r)

    echo -e "${B_GREEN}### Enabling zram swap to optimize memory usage \n  ${RESET}"
    echo "ALGO=zstd" | sudo tee -a /etc/default/zramswap
    echo "PERCENT=50" | sudo tee -a /etc/default/zramswap
    sudo systemctl restart zramswap.service
}

function fn_setup_firewall() {
    echo -e "${B_GREEN}### Installing ufw firewall \n  ${RESET}"
    sudo apt install -y ufw

    echo -e "${B_GREEN}### Setting up ufw firewall \n  ${RESET}"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw allow 554/udp

    echo -e "${IBG_YELLOW}${B_BLACK}Enter ${B_RED}'y'${IBG_YELLOW}${B_BLACK} below to activate the firewall ↴ ${RESET}"
    sudo ufw enable
    sudo ufw status verbose
}

function fn_block_outbound_connections_to_iran() {
    echo -e "${B_GREEN}### Installing required packages for GeoIP blocking \n  ${RESET}"
    sudo apt install -y \
        xtables-addons-dkms \
        xtables-addons-common \
        libtext-csv-xs-perl \
        libmoosex-types-netaddr-ip-perl \
        pkg-config \
        iptables-persistent \
        lsb-release \
        gzip \
        wget

    # Download the latest GeoIP database
    MON=$(date +"%m")
    YR=$(date +"%Y")
    sudo mkdir /usr/share/xt_geoip
    sudo wget "https://download.db-ip.com/free/dbip-country-lite-${YR}-${MON}.csv.gz" -O /usr/share/xt_geoip/dbip-country-lite.csv.gz
    sudo gunzip /usr/share/xt_geoip/dbip-country-lite.csv.gz

    # Convert CSV database to binary format for xt_geoip
    DISTRO_VERSION=$(lsb_release -sr)
    if [[ "$DISTRO" =~ "Ubuntu" ]]; then
        if (($(echo "$DISTRO_VERSION == 20.04" | bc -l))); then
            sudo /usr/lib/xtables-addons/xt_geoip_build -D /usr/share/xt_geoip/ -S /usr/share/xt_geoip/
        elif (($(echo "$DISTRO_VERSION == 22.04" | bc -l))); then
            sudo /usr/libexec/xtables-addons/xt_geoip_build -s -i /usr/share/xt_geoip/dbip-country-lite.csv.gz
        fi
    elif [[ "$DISTRO" =~ "Debian GNU/Linux" ]]; then
        if (($(echo "$DISTRO_VERSION == 11" | bc -l))); then
            sudo /usr/libexec/xtables-addons/xt_geoip_build -s -i /usr/share/xt_geoip/dbip-country-lite.csv.gz
        fi
    fi

    # Load xt_geoip kernel module
    modprobe xt_geoip
    lsmod | grep ^xt_geoip

    # Block outgoing connections to Iran
    sudo iptables -A OUTPUT -m geoip --dst-cc IR -j DROP

    # Save and cleanup
    sudo iptables-save | sudo tee /etc/iptables/rules.v4
    sudo ip6tables-save | sudo tee /etc/iptables/rules.v6
    sudo rm /usr/share/xt_geoip/dbip-country-lite.csv

    echo -e "${B_GREEN}### Disabling local DNSStubListener \n  ${RESET}"
    sudo mkdir -p /etc/systemd/resolved.conf.d
    sudo touch /etc/systemd/resolved.conf.d/nostublistener.conf
    nostublistener="[Resolve]\n
    DNS=127.0.0.1\n
    DNSStubListener=no"
    nostublistener="${nostublistener// /}"
    echo -e $nostublistener | awk '{$1=$1};1' | sudo tee /etc/systemd/resolved.conf.d/nostublistener.conf >/dev/null
    sudo systemctl reload-or-restart systemd-resolved
    DNS_FILTERING=true
}

function fn_harden_ssh_security() {
    echo -e "${B_GREEN}### Installing fail2ban \n  ${RESET}"
    sudo apt install -y fail2ban

    echo -e "${B_GREEN}### Hardening SSH against brute-force \n  ${RESET}"
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    fail2ban_contents="[sshd]
        enabled = true
        port = ssh
        filter = sshd
        logpath = /var/log/auth.log
        maxretry = 5
        findtime = 300
        bantime = 3600
        ignoreip = 127.0.0.1"
    fail2ban_contents="${fail2ban_contents// /}"
    echo -e "${fail2ban_contents}" | sudo tee /etc/fail2ban/jail.local >/dev/null
    sudo systemctl restart fail2ban.service
}

function fn_install_docker() {
    # Update OS
    echo -e " ${B_GREEN}### Updating the repository cache \n ${RESET}"
    sudo apt update
    sudo apt upgrade -y

    echo -e "${B_GREEN}### Installing required packages for Docker \n  ${RESET}"
    sudo apt install -y \
        openssl \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    if [[ $DISTRO =~ "Ubuntu" ]]; then
        echo -e "${GREEN}Setting up Docker repositories \n ${RESET}"
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt-get update

        echo -e \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    elif [[ $DISTRO =~ "Debian GNU/Linux" ]]; then
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo -e \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi

    echo -e "${GREEN}Installing Docker from official repository \n ${RESET}"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    echo -e "${GREEN}Enabling Rootless Docker Execution \n ${RESET}"
    sudo usermod -aG docker $USER
    sudo systemctl daemon-reload
    sudo systemctl enable --now docker
    sudo systemctl enable --now containerd

    # Test installation
    sudo docker run hello-world

    echo -e "${B_GREEN}*** Docker is now installed! *** \n ${RESET}"
    # newgrp docker
}

# Functions
function fn_prompt_domain() {
    echo ""
    while true; do
        DOMAIN=""
        while [[ $DOMAIN = "" ]]; do
            read -r -p "Enter your domain name: " DOMAIN
        done
        read -p "$(echo -e "Do you confirm ${YELLOW}\"${DOMAIN}\"${RESET}? (Y/n): ")" confirm
        if [[ "$confirm" == [yY] || "$confirm" == [yY][eE][sS] || "$confirm" == "" ]]; then
            break
        else
            echo -e "Okay! Let's try that again..."
            continue
        fi
    done
}

function fn_prompt_subdomain() {
    echo ""
    local -n input=$2 # Pass var by reference

    while true; do
        input=""
        while [[ $input = "" ]]; do
            read -r -p "$1: " input
        done
        read -p "$(echo -e "Do you confirm ${YELLOW}\"${input}\"${RESET}? (Y/n): ")" confirm
        if [[ "$confirm" == [yY] || "$confirm" == [yY][eE][sS] || "$confirm" == "" ]]; then
            if [[ "${SNI_ARR[*]}" =~ ${input} ]]; then
                echo -e "\n${B_RED}ERROR: This subdomain is already reserved for another proxy, enter another one!${RESET}"
                continue
            else
                SNI_ARR+=(${input})
                break
            fi
        else
            echo -e "Okay! Let's try that again..."
            continue
        fi
    done
}

function fn_xray_add_xtls() {
    xray_entry="{
            \"listen\": \"0.0.0.0\",
            \"port\": 3443,
            \"protocol\": \"vless\",
            \"settings\": {
                \"clients\": [
                    {
                        \"id\": \"${XTLS_UUID}\",
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
                            \"certificateFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${XTLS_SUBDOMAIN}/${XTLS_SUBDOMAIN}.crt\",
                            \"keyFile\": \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${XTLS_SUBDOMAIN}/${XTLS_SUBDOMAIN}.key\"
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
                                    \"${XTLS_SUBDOMAIN}\"
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
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${XTLS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${XTLS_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${XTLS_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2
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
                \"grpcSettings\": {
                    \"serviceName\": \"${TROJAN_GRPC_SERVICENAME}\"
                },
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
                \"wsSettings\": {
                    \"path\": \"/${TROJAN_WS_PATH}\",
                    \"host\": [
                        \"${TROJAN_WS_SUBDOMAIN}\"
                    ]
                },
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
                \"wsSettings\": {
                    \"path\": \"/${VMESS_WS_PATH}\",
                    \"host\": [
                        \"${VMESS_WS_SUBDOMAIN}\"
                    ]
                },
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

function fn_configure_xray() {
    if [ -v "${XTLS_SUBDOMAIN}" ]; then
        fn_xray_add_xtls $1 $2
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

function fn_configure_mtproto_users() {
    sed -i -e "s/\<TG_SECRET\>/$TG_SECRET/" $1
}

function fn_configure_mtproto() {
    # This is a TOML file so we revert to sed
    sed -i -e "s/\<MTPROTO_SUBDOMAIN\>/$MTPROTO_SUBDOMAIN/g" $1
    # Edit Caddy config.json
    caddy_entry="{
                    \"match\": [
                        {
                            \"tls\": {
                                \"sni\": [
                                    \"${MTPROTO_SUBDOMAIN}\"
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
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${MTPROTO_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${MTPROTO_SUBDOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${MTPROTO_SUBDOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $2

}

function fn_configure_hysteria() {
    tmp_hysteria=$(jq ".obfs = \"${HYSTERIA_PASSWORD}\"" $1)
    tmp_hysteria=$(jq ".cert = \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${HYSTERIA_SUBDOMAIN}/${HYSTERIA_SUBDOMAIN}.crt\"" <<<"$tmp_hysteria")
    jq ".key = \"/etc/letsencrypt/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${HYSTERIA_SUBDOMAIN}/${HYSTERIA_SUBDOMAIN}.key\"" <<<"$tmp_hysteria" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_configure_hysteria_client() {
    tmp_hysteria=$(jq ".obfs = \"${HYSTERIA_PASSWORD}\"" $1)
    tmp_hysteria=$(jq ".server = \"${HYSTERIA_SUBDOMAIN}:554\"" <<<"$tmp_hysteria")
    jq ".server_name = \"${HYSTERIA_SUBDOMAIN}\"" <<<"$tmp_hysteria" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_configure_caddy() {
    tmp_caddy=$(jq ".apps.tls.certificates.automate += [\"${DOMAIN}\"]" $1)
    tmp_caddy=$(jq ".apps.tls.automation.policies[0].subjects += [\"${DOMAIN}\"]" <<<"$tmp_caddy")
    tmp_caddy=$(jq ".apps.http.servers.web.routes[0].match[0].host += [\"${DOMAIN}\"]" <<<"$tmp_caddy")
    jq ".apps.http.servers.web.tls_connection_policies[0].match.sni += [\"${DOMAIN}\"]" <<<"$tmp_caddy" >/tmp/tmp.json && mv /tmp/tmp.json $1
}

function fn_setup_docker() {
    echo -e "${GREEN}Creating Docker volumes and networks ${RESET}"
    sudo docker volume create caddy_data
    sudo docker volume create caddy_config
    sudo docker volume create sockets
    sudo docker network create caddy
}

function fn_spinup_docker_containers() {
    echo -e "${GREEN}Spinning up Caddy Docker container${RESET}"
    sudo docker compose -f $DOCKER_DST_DIR/caddy/docker-compose.yml up -d
    echo -e "${CYAN}Waiting 10 seconds for TLS certificates to fully download..."
    sleep 10
    echo -e "${GREEN}Spinning up proxy Docker container${RESET}"
    if [ $DNS_FILTERING = true ]; then
        sudo docker compose -f $DOCKER_DST_DIR/blocky/docker-compose.yml up -d
        sleep 1
    fi
    sudo docker compose -f $DOCKER_DST_DIR/xray/docker-compose.yml up -d
    sleep 1
    sudo docker compose -f $DOCKER_DST_DIR/hysteria/docker-compose.yml up -d
    sleep 1
    sudo docker compose -f $DOCKER_DST_DIR/mtproto/docker-compose.yml up -d
}

function fn_clone_html_templates() {
    git clone https://github.com/designmodo/html-website-templates.git
    cd html-website-templates
    #TODO: To be implemeneted!
}

function fn_cleanup_source_dir() {
    if [ -d $DOCKER_SRC_DIR ]; then
        rm -rf $DOCKER_SRC_DIR
        mkdir -p $DOCKER_SRC_DIR
        cp -r ./Docker/* $DOCKER_SRC_DIR
    else
        mkdir -p $DOCKER_SRC_DIR
        cp -r ./Docker/* $DOCKER_SRC_DIR
    fi
}

function fn_cleanup_destination_dir() {
    if [ -d $DOCKER_DST_DIR ]; then
        rm -rf $DOCKER_DST_DIR
        mkdir -p $DOCKER_DST_DIR
        cp -r $DOCKER_SRC_DIR/* $DOCKER_SRC_DIR
        if [ $DNS_FILTERING = false ]; then
            rm -rf $DOCKER_DST_DIR/blocky
        fi
    else
        mkdir -p $DOCKER_DST_DIR
        cp -r $DOCKER_SRC_DIR/* $DOCKER_SRC_DIR
        if [ $DNS_FILTERING = false ]; then
            rm -rf $DOCKER_DST_DIR/blocky
        fi
    fi
}

function fn_start_proxies() {
    dpkg --status docker-ce &>/dev/null
    if [ $? -eq 0 ]; then
        if [ -v "${DOMAIN}" ]; then
            fn_cleanup_source_dir
            fn_configure_xray "${DOCKER_SRC_DIR}/xray/etc/xray.json" "${DOCKER_SRC_DIR}/caddy/etc/caddy.json"
            fn_configure_mtproto "${DOCKER_SRC_DIR}/mtproto/config/config.toml" "${DOCKER_SRC_DIR}/caddy/etc/caddy.json"
            fn_configure_mtproto_users "${DOCKER_SRC_DIR}/mtproto/config/users.toml"
            fn_configure_hysteria "${DOCKER_SRC_DIR}/hysteria/etc/hysteria.json"
            fn_configure_hysteria_client "${DOCKER_SRC_DIR}/hysteria/client/hysteria.json"
            fn_configure_caddy "${DOCKER_SRC_DIR}/caddy/etc/caddy.json"
            fn_cleanup_destination_dir
            fn_setup_docker
            fn_spinup_docker_containers
        else
            echo -e "${B_RED}ERROR: You have to first configure the proxy settings (option 2 in the menu)!${RESET}"
        fi
    else
        echo -e "${B_RED}Docker is missing! Select option 1 in the main menu to install.${RESET}"
    fi
}

function fn_get_client_configs() {
    if [ -v "${DOMAIN}" ]; then
        touch $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        if [ -v "${XTLS_SUBDOMAIN}" ]; then
            echo -e "vless://${XTLS_UUID}@${XTLS_SUBDOMAIN}:443?security=tls&encryption=none&alpn=h2,http/1.1&headerType=none&type=tcp&flow=xtls-rprx-vision-udp443&sni=${XTLS_SUBDOMAIN}#0xLem0nade+XTLS" >>$DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi
        if [ -v "${TROJAN_H2_SUBDOMAIN}" ]; then
            echo -e "trojan://${TROJAN_H2_PASSWORD}@${TROJAN_H2_SUBDOMAIN}:443?path=${TROJAN_H2_PATH}&security=tls&alpn=h2,http/1.1&host=${TROJAN_H2_SUBDOMAIN}&type=http&sni=${TROJAN_H2_SUBDOMAIN}#0xLem0nade+Trojan+H2" >>$DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi
        if [ -v "${TROJAN_GRPC_SUBDOMAIN}" ]; then
            echo -e "trojan://${TROJAN_GRPC_PASSWORD}@${TROJAN_GRPC_SUBDOMAIN}:443?mode=gun&security=tls&alpn=h2,http/1.1&type=grpc&serviceName=${TROJAN_GRPC_SERVICENAME}&sni=${TROJAN_GRPC_SUBDOMAIN}#0xLem0nade+Trojan+gRPC" >>$DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi
        if [ -v "${TROJAN_WS_SUBDOMAIN}" ]; then
            echo -e "trojan://${TROJAN_WS_PASSWORD}@${TROJAN_WS_SUBDOMAIN}:443?path=${TROJAN_WS_PATH}&security=tls&alpn=h2,http/1.1&host=${TROJAN_WS_SUBDOMAIN}&type=ws&sni=${TROJAN_WS_SUBDOMAIN}#0xLem0nade+Trojan+WS" >>$DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi
        if [ -v "${VMESS_WS_SUBDOMAIN}" ]; then
            vmess_config="{\"add\":\"${VMESS_WS_SUBDOMAIN}\",\"aid\":\"0\",\"alpn\":\"h2,http/1.1\",\"host\":\"${VMESS_WS_SUBDOMAIN}\",\"id\":\"${VMESS_WS_UUID}\",\"net\":\"ws\",\"path\":\"${VMESS_WS_PATH}\",\"port\":\"443\",\"ps\":\"Vmess\",\"scy\":\"none\",\"sni\":\"${VMESS_WS_SUBDOMAIN}\",\"tls\":\"tls\",\"type\":\"\",\"v\":\"2\"}"
            vmess_config=$(echo $vmess_config | base64 | tr -d '\n')
            echo -e "vmess://${vmess_config}" >>$DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi
        mkdir -p $DOCKER_DST_DIR/clients
        cp $DOCKER_DST_DIR/xray/client/xray_share_urls.txt $DOCKER_DST_DIR/clients/xray_share_urls.txt
        cp $DOCKER_DST_DIR/hysteria/client/hysteria.json $DOCKER_DST_DIR/clients/hysteria.json
        cp $DOCKER_DST_DIR/mtproto/client/share_urls.txt $DOCKER_DST_DIR/clients/telegram_share_urls.txt
        zip -r $HOME/proxy-clients.zip $DOCKER_DST_DIR/clients/*
        echo -e "${GREEN}Finished! You can now download client config files 'proxy-clients.zip' inside HOME directory. ${RESET}"
    else
        echo -e "${B_RED}ERROR: You have to first configure the proxy settings (option 2 in the menu)!${RESET}"
    fi

}
