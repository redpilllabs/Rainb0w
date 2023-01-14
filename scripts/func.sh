#!/bin/bash

source func_docker.sh
source func_xray.sh
source func_hysteria.sh
source func_mtproto.sh

# Functions
function fn_prompt_domain() {
    echo ""
    while true; do
        CAMOUFLAGE_DOMAIN=""
        while [[ $CAMOUFLAGE_DOMAIN = "" ]]; do
            read -r -p "Enter your camouflage domain name: " CAMOUFLAGE_DOMAIN
        done
        read -p "$(echo -e "Do you confirm ${YELLOW}\"${CAMOUFLAGE_DOMAIN}\"${RESET}? (Y/n): ")" confirm
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

function fn_check_for_pkg() {
    if [ $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        sudo apt install -y $1
    fi

}

function fn_upgrade_os() {
    trap - INT
    # Update OS
    echo -e " ${B_GREEN}### Updating the operating system \n ${RESET}"
    sudo apt update
    sudo apt upgrade -y
}

function fn_tune_system() {
    echo -e "${B_GREEN}### Tuning system network stack for best performance${RESET}"
    if [ ! -d "/etc/sysctl.d" ]; then
        sudo mkdir -p /etc/sysctl.d
    fi
    sudo touch /etc/sysctl.d/99-sysctl.conf
    echo "net.core.rmem_max=4000000" | sudo tee -a /etc/sysctl.d/99-sysctl.conf >/dev/null
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.d/99-sysctl.conf >/dev/null
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.d/99-sysctl.conf >/dev/null
    echo "net.ipv4.tcp_slow_start_after_idle=0" | sudo tee -a /etc/sysctl.d/99-sysctl.conf >/dev/null
    sudo sysctl -p /etc/sysctl.d/99-sysctl.conf
    echo -e "${B_GREEN}Done!${RESET}"
    sleep 1
}

function fn_setup_zram() {
    trap - INT
    echo -e "${B_GREEN}### Installing required packages for ZRam swap \n  ${RESET}"
    sudo apt install -y zram-tools linux-modules-extra-$(uname -r)

    echo -e "${B_GREEN}### Enabling zram swap to optimize memory usage \n  ${RESET}"
    echo "ALGO=zstd" | sudo tee -a /etc/default/zramswap
    echo "PERCENT=50" | sudo tee -a /etc/default/zramswap
    sudo systemctl restart zramswap.service
}

function fn_setup_firewall() {
    trap - INT
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
    trap - INT
    if [ "$DISTRO_VERSION" == "20.04" ]; then
        echo -e "${RED}xt_geoip module on Ubuntu 20.04 needs MaxMind database which is no longer available without a license! You need to upgrade to 22.04!"
        return 1
    fi
    echo -e "${B_GREEN}### Installing required packages for GeoIP blocking \n  ${RESET}"
    sudo apt install -y \
        xtables-addons-dkms \
        xtables-addons-common \
        libtext-csv-xs-perl \
        libmoosex-types-netaddr-ip-perl \
        pkg-config \
        iptables-persistent \
        gzip \
        wget \
        cron

    # Download the latest GeoIP database
    MON=$(date +"%m")
    YR=$(date +"%Y")
    if [ ! -d "/usr/share/xt_geoip" ]; then
        sudo mkdir /usr/share/xt_geoip
    fi

    sudo curl -s "https://download.db-ip.com/free/dbip-country-lite-${YR}-${MON}.csv.gz" >/usr/share/xt_geoip/dbip-country-lite-$YR-$MON.csv.gz
    sudo gunzip /usr/share/xt_geoip/dbip-country-lite-$YR-$MON.csv.gz

    # Convert CSV database to binary format for xt_geoip
    sudo /usr/libexec/xtables-addons/xt_geoip_build -s -i /usr/share/xt_geoip/dbip-country-lite-$YR-$MON.csv

    # Load xt_geoip kernel module
    modprobe xt_geoip
    lsmod | grep ^xt_geoip

    # Block outgoing connections to Iran
    sudo iptables -A OUTPUT -m geoip --dst-cc IR -j DROP

    # Save and cleanup
    sudo iptables-save | sudo tee /etc/iptables/rules.v4
    sudo ip6tables-save | sudo tee /etc/iptables/rules.v6
    sudo rm /usr/share/xt_geoip/dbip-country-lite-$YR-$MON.csv

    echo -e "${B_GREEN}### Disabling local DNSStubListener \n  ${RESET}"
    if [ ! -d "/etc/systemd/resolved.conf.d" ]; then
        sudo mkdir -p /etc/systemd/resolved.conf.d
    fi

    if [ ! -f "/etc/systemd/resolved.conf.d/nostublistener.conf" ]; then
        sudo touch /etc/systemd/resolved.conf.d/nostublistener.conf
        nostublistener="[Resolve]\n
        DNS=127.0.0.1\nDNSStubListener=no"
        nostublistener="${nostublistener// /}"
        echo -e $nostublistener | awk '{$1=$1};1' | sudo tee /etc/systemd/resolved.conf.d/nostublistener.conf >/dev/null
        sudo systemctl reload-or-restart systemd-resolved
    fi

    DNS_FILTERING=true
}

function fn_enable_xtgeoip_cronjob() {
    if [ "$(lsmod | grep ^xt_geoip)" ]; then
        # Enable cronjobs service for future automatic updates
        sudo systemctl enable cron
        if [ ! "$(cat /etc/crontab | grep ^xt_geoip_update)" ]; then
            echo -e "${B_GREEN}### Adding cronjob to update xt_goip database \n  ${RESET}"
            sudo cp $PWD/scripts/xt_geoip_update.sh /usr/share/xt_geoip/xt_geoip_update.sh
            sudo chmod +x /usr/share/xt_geoip/xt_geoip_update.sh
            sudo touch /etc/crontab
            # Run on the second day of each month
            echo "0 0 2 * * root bash /usr/share/xt_geoip/xt_geoip_update.sh >/tmp/xt_geoip_update.log" | sudo tee -a /etc/crontab >/dev/null
        else
            echo -e "${YELLOW}### Cronjob already exists! \n  ${RESET}"
        fi
    else
        echo -e "${B_RED}### xt_geoip Kernel module is not loaded! \n  ${RESET}"
    fi
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
        cp -r $DOCKER_SRC_DIR/* $DOCKER_DST_DIR
        if [ $DNS_FILTERING = false ]; then
            rm -rf $DOCKER_DST_DIR/blocky
        fi
    else
        mkdir -p $DOCKER_DST_DIR
        cp -r $DOCKER_SRC_DIR/* $DOCKER_DST_DIR
        if [ $DNS_FILTERING = false ]; then
            rm -rf $DOCKER_DST_DIR/blocky
        fi
    fi
}

function fn_start_proxies() {
    trap - INT
    dpkg --status docker-ce &>/dev/null
    if [ $? -eq 0 ]; then
        dpkg --status jq &>/dev/null
        if [ $? -eq 0 ]; then
            if [ ${#SNI_ARR[@]} -eq 0 ]; then
                echo -e "${B_RED}ERROR: You have to first add your proxy domains (option 2 in the main menu)!${RESET}"
            else
                fn_cleanup_source_dir
                fn_configure_xray "${DOCKER_SRC_DIR}/xray/etc/xray.json" "${DOCKER_SRC_DIR}/caddy/etc/caddy.json"
                fn_configure_mtproto "${DOCKER_SRC_DIR}/mtproto/config/config.toml" "${DOCKER_SRC_DIR}/caddy/etc/caddy.json"
                fn_configure_mtproto_users "${DOCKER_SRC_DIR}/mtproto/config/users.toml"
                fn_configure_hysteria "${DOCKER_SRC_DIR}/hysteria/etc/hysteria.json"
                fn_configure_hysteria_client "${DOCKER_SRC_DIR}/hysteria/client/hysteria.json"
                if [ ! -z "${CAMOUFLAGE_DOMAIN}" ]; then
                    fn_configure_camouflage_website "${DOCKER_SRC_DIR}/caddy/etc/caddy.json"
                fi
                fn_cleanup_destination_dir
                fn_setup_docker
                fn_spinup_docker_containers
            fi
        else
            echo -e "${B_RED}jq is missing! Install with [sudo apt install jq]${RESET}"
        fi
    else
        echo -e "${B_RED}Docker is missing! Select option 1 in the main menu to install.${RESET}"
    fi
}

function fn_get_client_configs() {
    trap - INT
    fn_check_for_pkg zip
    if [ ${#SNI_ARR[@]} -eq 0 ]; then
        echo -e "${B_RED}ERROR: You have to first add your proxy domains (option 2 in the main menu)!${RESET}"
    else
        # Create and notify about HOME/proxy-clients.zip
        # touch $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        if [ ! -z "${XTLS_SUBDOMAIN}" ]; then
            echo -e "\nvless://${XTLS_UUID}@${XTLS_SUBDOMAIN}:443?security=tls&encryption=none&alpn=h2,http/1.1&headerType=none&type=tcp&flow=xtls-rprx-vision-udp443&sni=${XTLS_SUBDOMAIN}#0xLem0nade+XTLS\n" >>$DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi
        if [ ! -z "${TROJAN_H2_SUBDOMAIN}" ]; then
            echo "trojan://${TROJAN_H2_PASSWORD}@${TROJAN_H2_SUBDOMAIN}:443?path=${TROJAN_H2_PATH}&security=tls&alpn=h2,http/1.1&host=${TROJAN_H2_SUBDOMAIN}&type=http&sni=${TROJAN_H2_SUBDOMAIN}#0xLem0nade+Trojan+H2" >>$DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi
        if [ ! -z "${TROJAN_GRPC_SUBDOMAIN}" ]; then
            echo -e "\ntrojan://${TROJAN_GRPC_PASSWORD}@${TROJAN_GRPC_SUBDOMAIN}:443?mode=gun&security=tls&alpn=h2,http/1.1&type=grpc&serviceName=${TROJAN_GRPC_SERVICENAME}&sni=${TROJAN_GRPC_SUBDOMAIN}#0xLem0nade+Trojan+gRPC \n" >>$DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi
        if [ ! -z "${TROJAN_WS_SUBDOMAIN}" ]; then
            echo "\n"
            echo "trojan://${TROJAN_WS_PASSWORD}@${TROJAN_WS_SUBDOMAIN}:443?path=${TROJAN_WS_PATH}&security=tls&alpn=h2,http/1.1&host=${TROJAN_WS_SUBDOMAIN}&type=ws&sni=${TROJAN_WS_SUBDOMAIN}#0xLem0nade+Trojan+WS" >>$DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi
        if [ ! -z "${VMESS_WS_SUBDOMAIN}" ]; then
            echo "\n"
            vmess_config="{\"add\":\"${VMESS_WS_SUBDOMAIN}\",\"aid\":\"0\",\"alpn\":\"h2,http/1.1\",\"host\":\"${VMESS_WS_SUBDOMAIN}\",\"id\":\"${VMESS_WS_UUID}\",\"net\":\"ws\",\"path\":\"${VMESS_WS_PATH}\",\"port\":\"443\",\"ps\":\"Vmess\",\"scy\":\"none\",\"sni\":\"${VMESS_WS_SUBDOMAIN}\",\"tls\":\"tls\",\"type\":\"\",\"v\":\"2\"}"
            vmess_config=$(echo $vmess_config | base64 | tr -d '\n')
            echo "vmess://${vmess_config}" >>$DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi

        # Print share URLs
        if [ -f "$DOCKER_DST_DIR/xray/client/xray_share_urls.txt" ]; then
            echo -e "${GREEN}########################################"
            echo -e "#           Xray/v2ray Proxies         #"
            echo -e "########################################${RESET}"
            cat $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        fi
        if [ ! -z "${MTPROTO_SUBDOMAIN}" ]; then
            echo -e "${GREEN}########################################"
            echo -e "#           Telegram Proxies           #"
            echo -e "########################################${RESET}"
            cat $DOCKER_DST_DIR/mtproto/client/share_urls.txt
        fi
        if [ ! -z "${HYSTERIA_SUBDOMAIN}" ]; then
            echo -e "${GREEN}########################################"
            echo -e "#           Hysteria config            #"
            echo -e "########################################${RESET}"
            cat $DOCKER_DST_DIR/hysteria/client/hysteria.json
        fi

        echo -e "${MAGENTA}Zipping all the share url text files inside ${HOME}/proxy-clients.zip\n"
        zip -q $HOME/proxy-clients.zip $DOCKER_DST_DIR/hysteria/client/hysteria.json $DOCKER_DST_DIR/mtproto/client/share_urls.txt $DOCKER_DST_DIR/xray/client/xray_share_urls.txt
        PUBLIC_IP=$(curl -s icanhazip.com)
        echo -e "${GREEN}\nYou can also find these urls and configs inside HOME/proxy-clients.zip ${RESET}"
        echo -e "${GREEN}To download this file, you can use Filezilla to FTP or run the command below on your local computer :\n ${RESET}"
        echo -e "${CYAN}scp ${USER}@${PUBLIC_IP}:~/proxy-clients.zip ~/Downloads/proxy-clients.zip${RESET}"

        if [ ! -z "${CAMOUFLAGE_DOMAIN}" ]; then
            echo -e "${GREEN}Place your static HTML files inside '${HOME}/Docker/caddy/www' for your camouflage website."
        fi

        echo -e "\nAll done! You can now connect to your proxies!"
    fi
}
