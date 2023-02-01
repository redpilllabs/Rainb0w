#!/bin/bash

##### DNS control functions #####

function fn_enable_dns_filtering() {
    local IS_DOCKER_INSTALLED=$(fn_check_for_pkg docker-ce)
    if [ "$IS_DOCKER_INSTALLED" = true ]; then
        if [ ! -f "/etc/systemd/resolved.conf.d/nostublistener.conf" ]; then
            echo -e "${B_GREEN}Preparing the system to setup a DNS resolver ${RESET}"
            if [ ! -d "/etc/systemd/resolved.conf.d" ]; then
                sudo mkdir -p /etc/systemd/resolved.conf.d
            fi
            sudo touch /etc/systemd/resolved.conf.d/nostublistener.conf
            nostublistener="[Resolve]\n
            DNS=127.0.0.1\n
            DNSStubListener=no"
            nostublistener="${nostublistener// /}"
            echo -e $nostublistener | awk '{$1=$1};1' | sudo tee /etc/systemd/resolved.conf.d/nostublistener.conf >/dev/null
            sudo systemctl reload-or-restart systemd-resolved
            echo -e "${B_GREEN}<< Finished! >>${RESET}"
        fi
    else
        echo -e "${B_YELLOW}\n\nNOTICE: Docker is missing! Reinstalling now, please wait... ${RESET}"
        fn_install_docker
    fi
}

function fn_restart_blocky() {
    local IS_DOCKER_INSTALLED=$(fn_check_for_pkg docker-ce)
    if [ "$IS_DOCKER_INSTALLED" = true ]; then
        local IS_CONTAINER_RUNNING=$(fn_is_container_running blocky)
        if [ "$IS_CONTAINER_RUNNING" = true ]; then
            echo -e "${B_GREEN}Restarting blocky container to apply the changes!"
            docker compose -f $DOCKER_HOME/blocky/docker-compose.yml down --remove-orphans
            sleep 1
            docker compose -f $DOCKER_HOME/blocky/docker-compose.yml up -d
        fi
    else
        echo -e "${B_YELLOW}\n\nNOTICE: Docker is missing! Reinstalling now, please wait... ${RESET}"
        fn_install_docker
    fi
}

##### IP control functions #####

function fn_increase_connctrack_limit() {
    local MEM=$(free | awk '/^Mem:/{print $2}' | awk '{print $1*1000}')
    local CONNTRACK_MAX=$(awk "BEGIN {print $MEM / 16384 / 2}")
    if [ "$(sysctl -n net.netfilter.nf_conntrack_max)" -ne "$CONNTRACK_MAX" ]; then
        if [ ! -d "/etc/sysctl.d" ]; then
            sudo mkdir -p /etc/sysctl.d
        fi
        if [ ! -f "/etc/sysctl.d/99-x-firewall.conf" ]; then
            echo -e "${GREEN}Increasing Connection State Tracking Limits ${RESET}"
            sudo touch /etc/sysctl.d/99-x-firewall.conf
            echo "net.netfilter.nf_conntrack_max=$CONNTRACK_MAX" | sudo tee -a /etc/sysctl.d/99-x-firewall.conf
            sudo sysctl -p /etc/sysctl.d/99-x-firewall.conf
            echo -e "${B_GREEN}<<< Finished kernel tuning! >>> ${RESET}"
        fi
    fi
}

function fn_setup_firewall() {
    trap - INT

    if [ ! -f "/etc/iptables/rules.v4" ] ||
        [ ! "$(cat /etc/iptables/rules.v4 | grep 'Allow loopback connections - Rainbow')" ]; then
        fn_check_and_install_pkg iptables-persistent

        echo -e "${B_GREEN}Flushing iptables rules to begin with a clean slate${RESET}"
        sudo iptables -t nat -F
        sudo ip6tables -t nat -F
        sudo iptables -t mangle -F
        sudo ip6tables -t mangle -F
        sudo iptables -F
        sudo ip6tables -F
        sudo iptables -X
        sudo ip6tables -X

        echo -e "${B_GREEN}Allow already established connections by other rules${RESET}"
        sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        sudo ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
        sudo ip6tables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT

        echo -e "${B_GREEN}Allow local loopback connections ${RESET}"
        sudo iptables -A INPUT -i lo -m comment --comment "Allow loopback connections - Rainbow" -j ACCEPT
        sudo ip6tables -A INPUT -i lo -m comment --comment "Allow loopback connections - Rainbow" -j ACCEPT
        sudo iptables -A OUTPUT -o lo -m comment --comment "Allow loopback connections - Rainbow" -j ACCEPT
        sudo ip6tables -A OUTPUT -o lo -m comment --comment "Allow loopback connections - Rainbow" -j ACCEPT

        echo -e "${B_GREEN}Allow ping ${RESET}"
        sudo iptables -A INPUT -p icmp --icmp-type 8 -m conntrack --ctstate NEW -m comment --comment "Allow ping" -j ACCEPT

        echo -e "${B_GREEN}Allow incoming and outgoing SSH ${RESET}"
        sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m comment --comment "Allow incoming SSH" -j ACCEPT
        sudo iptables -A INPUT -p tcp --sport 22 -m conntrack --ctstate NEW -m comment --comment "Allow outgoing SSH" -j ACCEPT
        sudo iptables -A OUTPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m comment --comment "Allow outgoing SSH" -j ACCEPT

        echo -e "${B_GREEN}Allow incoming HTTP and HTTPS/QUIC ${RESET}"
        sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m comment --comment "Allow HTTP" -j ACCEPT
        sudo ip6tables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m comment --comment "Allow HTTP" -j ACCEPT
        sudo iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -m comment --comment "Allow HTTPS" -j ACCEPT
        sudo ip6tables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -m comment --comment "Allow HTTPS" -j ACCEPT
        sudo iptables -A INPUT -p udp --dport 443 -m conntrack --ctstate NEW -m comment --comment "Allow QUIC" -j ACCEPT
        sudo ip6tables -A INPUT -p udp --dport 443 -m conntrack --ctstate NEW -m comment --comment "Allow QUIC" -j ACCEPT

        echo -e "${B_GREEN}Allow incoming DNS-over-TLS/QUIC ${RESET}"
        sudo iptables -A INPUT -p tcp --dport 853 -m conntrack --ctstate NEW -m comment --comment "Allow DoT" -j ACCEPT
        sudo ip6tables -A INPUT -p tcp --dport 853 -m conntrack --ctstate NEW -m comment --comment "Allow DoT" -j ACCEPT
        sudo iptables -A INPUT -p udp --dport 853 -m conntrack --ctstate NEW -m comment --comment "Allow DoQ" -j ACCEPT
        sudo ip6tables -A INPUT -p udp --dport 853 -m conntrack --ctstate NEW -m comment --comment "Allow DoQ" -j ACCEPT

        # echo -e "${B_GREEN}Block invalid packets ${RESET}"
        # sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
        # sudo ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP

        echo -e "${B_GREEN}Setting default policies${RESET}"
        sudo iptables -P INPUT DROP
        sudo ip6tables -P INPUT DROP
        sudo iptables -P FORWARD ACCEPT
        sudo ip6tables -P FORWARD ACCEPT
        sudo iptables -P OUTPUT ACCEPT
        sudo ip6tables -P OUTPUT ACCEPT

        local IS_INSTALLED=$(fn_check_for_pkg docker-ce)
        if [ $IS_INSTALLED = true ]; then
            echo -e "${B_YELLOW}Restarting Docker service to re-insert its rules${RESET}"
            sudo service docker restart
        fi

        # Save
        sudo iptables-save | sudo tee /etc/iptables/rules.v4
        sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

        # Increase resource limits
        fn_increase_connctrack_limit

        echo -e "${B_GREEN}<<< Firewall setup finished! >>>${RESET}"
        sleep 1
    fi
}

function fn_logrotate_kernel() {
    # Remove kern.log from rsyslog since we're going to modify its settings
    sudo sed -i 's!/var/log/kern.log!!g' /etc/logrotate.d/rsyslog
    sudo sed -i '/^\s*$/d' /etc/logrotate.d/rsyslog

    if [ ! -f "/etc/logrotate.d/kernel" ]; then
        sudo touch /etc/logrotate.d/kernel
        sudo sh -c 'echo "/var/log/kern.log
{
	size 20M
    rotate 5
    copytruncate
	missingok
	notifempty
	compress
	delaycompress
	sharedscripts
	postrotate
		/usr/lib/rsyslog/rsyslog-rotate
	endscript
}" > /etc/logrotate.d/kernel'
    fi
}

function fn_install_xt_geoip_module() {
    trap - INT
    echo -e "${B_GREEN}Installing xt_geoip module ${RESET}"
    fn_check_and_install_pkg xtables-addons-dkms
    fn_check_and_install_pkg xtables-addons-common
    fn_check_and_install_pkg libtext-csv-xs-perl
    fn_check_and_install_pkg libmoosex-types-netaddr-ip-perl
    fn_check_and_install_pkg pkg-config
    fn_check_and_install_pkg iptables-persistent
    fn_check_and_install_pkg cron
    fn_check_and_install_pkg curl

    # Copy our builder script
    if [ ! -d "/usr/libexec/0xLem0nade" ]; then
        sudo mkdir -p /usr/libexec/0xLem0nade
    fi
    sudo cp $PWD/scripts/xt_geoip_build_agg /usr/libexec/0xLem0nade/xt_geoip_build_agg
    sudo chmod +x /usr/libexec/0xLem0nade/xt_geoip_build_agg

    # Rotate kernel logs and limit them to max 100MB
    fn_logrotate_kernel

    # Add cronjob to keep the databased updated
    sudo systemctl enable --now cron
    if [ ! "$(cat /etc/crontab | grep xt_geoip_update)" ]; then
        echo -e "${B_GREEN}Adding cronjob to update xt_goip database \n  ${RESET}"
        sudo cp $PWD/scripts/xt_geoip_update.sh /usr/libexec/0xLem0nade/xt_geoip_update.sh
        sudo chmod +x /usr/libexec/0xLem0nade/xt_geoip_update.sh
        sudo touch /etc/crontab
        # Check for updates daily
        echo "0 1 * * * root bash /usr/libexec/0xLem0nade/xt_geoip_update.sh >/tmp/xt_geoip_update.log" | sudo tee -a /etc/crontab >/dev/null
    fi
}

function fn_rebuild_xt_geoip_database() {
    if [ "$(fn_check_for_pkg xtables-addons-common)" = true ] &&
        [ "$(fn_check_for_pkg libtext-csv-xs-perl)" = true ]; then
        local XT_GEOIP_CODES=(IR CN RU XX YY)
        for item in ${XT_GEOIP_CODES[@]}; do
            if [ ! -f "/usr/share/xt_geoip/${item}.iv4" ]; then
                # Download the latest aggegated GeoIP database
                echo -e "${B_GREEN}xt_geoip database needes rebuilding! Downloading the latest aggregated CIDR .csv file ${RESET}"
                if [ ! -d "/usr/libexec/0xLem0nade/" ]; then
                    sudo mkdir -p /usr/libexec/0xLem0nade
                fi
                curl "https://raw.githubusercontent.com/0xLem0nade/GFIGeoIP/main/Aggregated_Data/agg_cidrs.csv" >/tmp/agg_cidrs.csv
                sudo mv /tmp/agg_cidrs.csv /usr/libexec/0xLem0nade/agg_cidrs.csv

                # Copy our builder script if coming from a previous version
                if [ ! -f "/usr/libexec/0xLem0nade/xt_geoip_build_agg" ]; then
                    sudo mkdir -p /usr/libexec/0xLem0nade
                fi
                sudo cp $PWD/scripts/xt_geoip_build_agg /usr/libexec/0xLem0nade/xt_geoip_build_agg
                sudo chmod +x /usr/libexec/0xLem0nade/xt_geoip_build_agg

                # Convert CSV database to binary format for xt_geoip
                echo -e "${B_GREEN}Converting to binary for xt_geoip kernel module utilization ${RESET}"
                if [ ! -d "/usr/share/xt_geoip" ]; then
                    sudo mkdir -p /usr/share/xt_geoip
                fi
                sudo /usr/libexec/0xLem0nade/xt_geoip_build_agg -s -i /usr/libexec/0xLem0nade/agg_cidrs.csv

                # Load the xt_geoip kernel module
                modprobe xt_geoip
                lsmod | grep ^xt_geoip
                break
            fi
        done
    else
        fn_install_xt_geoip_module
    fi
}

function fn_block_outgoing_iran() {
    sudo modprobe xt_geoip
    local IS_MODULE_LOADED=$(lsmod | grep ^xt_geoip)
    if [ ! -z "$IS_MODULE_LOADED" ]; then
        echo -e "${B_GREEN}\n\nBlocking OUTGOING connections to Iran ${RESET}"
        sleep 1

        sudo iptables -I FORWARD -m geoip --dst-cc IR -j REJECT
        sudo ip6tables -I FORWARD -m geoip --dst-cc IR -j REJECT

        # Save and cleanup
        sudo iptables-save | sudo tee /etc/iptables/rules.v4
        sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

        echo -e "${B_GREEN}\n\nBlocking .ir ccTLD by DNS${RESET}"
        sleep 1
        local IS_CCTLD_DNS_BLOCKED="$(yq '.blocking.clientGroupsBlock.default' ${BLOCKY_CONFIG_FILE} | grep 'ir_cctld')"
        if [ -z "$IS_CCTLD_DNS_BLOCKED" ]; then
            yq '.blocking.clientGroupsBlock.default += "ir_cctld"' ${BLOCKY_CONFIG_FILE} >${BLOCKY_CONFIG_FILE}
        fi
        fn_enable_dns_filtering
        fn_restart_blocky
    else
        echo -e "${B_YELLOW}\n\nNOTICE: xt_geoip module is missing! Reinstalling now, please wait... ${RESET}"
        fn_install_xt_geoip_module
    fi
}

function fn_unblock_outgoing_iran() {
    echo -e "${B_GREEN}\n\nUnblocking OUTGOING connections to Iran ${RESET}"
    sleep 1

    sudo iptables -D FORWARD -m geoip --dst-cc IR -j REJECT
    sudo ip6tables -D FORWARD -m geoip --dst-cc IR -j REJECT

    # Save and cleanup
    sudo iptables-save | sudo tee /etc/iptables/rules.v4
    sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

    echo -e "${B_GREEN}\n\nUnblocking .ir ccTLD by DNS${RESET}"
    sleep 1
    local IS_CCTLD_DNS_BLOCKED="$(yq '.blocking.clientGroupsBlock.default' ${BLOCKY_CONFIG_FILE} | grep 'ir_cctld')"
    if [ ! -z "$IS_CCTLD_DNS_BLOCKED" ]; then
        local IDX=$(yq '.blocking.clientGroupsBlock.default.[] | select(. == "ir_cctld") | path | .[-1]' $BLOCKY_CONFIG_FILE)
        yq "del(.blocking.clientGroupsBlock.default.[$IDX])" ${BLOCKY_CONFIG_FILE} >${BLOCKY_CONFIG_FILE}
    fi
    fn_restart_blocky
}

function fn_toggle_iran_outbound_blocking() {
    if [ "$BLOCK_IRAN_OUT_STATUS" = "DEACTIVATED" ]; then
        # Install xtables if not found already
        local IS_INSTALLED=$(fn_check_for_pkg xtables-addons-common)
        if [ "$IS_INSTALLED" = false ]; then
            fn_install_xt_geoip_module
        fi
        fn_setup_firewall
        fn_rebuild_xt_geoip_database
        fn_block_outgoing_iran
    else
        fn_unblock_outgoing_iran
    fi
}

function fn_update_iran_outbound_blocking_status() {
    local IS_MODULE_LOADED=$(lsmod | grep ^xt_geoip)
    if [ ! -z "$IS_MODULE_LOADED" ]; then
        if [ -f "/etc/iptables/rules.v4" ]; then
            local IS_IPTABLES_CONFIGURED=$(cat /etc/iptables/rules.v4 | grep 'FORWARD -m geoip --destination-country IR  -j REJECT')
            if [ "${IS_IPTABLES_CONFIGURED}" ]; then
                BLOCK_IRAN_OUT_STATUS="ACTIVATED"
                BLOCK_IRAN_OUT_STATUS_COLOR=$B_GREEN
            else
                BLOCK_IRAN_OUT_STATUS="DEACTIVATED"
                BLOCK_IRAN_OUT_STATUS_COLOR=$B_RED
            fi
        else
            BLOCK_IRAN_OUT_STATUS="DEACTIVATED"
            BLOCK_IRAN_OUT_STATUS_COLOR=$B_RED
        fi
    else
        BLOCK_IRAN_OUT_STATUS="DEACTIVATED"
        BLOCK_IRAN_OUT_STATUS_COLOR=$B_RED
    fi
}

function fn_block_china_in_out() {
    sudo modprobe xt_geoip
    local IS_MODULE_LOADED=$(lsmod | grep ^xt_geoip)
    if [ ! -z "$IS_MODULE_LOADED" ]; then
        echo -e "${B_GREEN}\n\nBlocking connections to/from China ${RESET}"
        sleep 1

        # Drop connections to/from China
        sudo iptables -I INPUT -m geoip --src-cc CN -j DROP
        sudo ip6tables -I INPUT -m geoip --src-cc CN -j DROP
        sudo iptables -I FORWARD -m geoip --dst-cc CN -j REJECT
        sudo ip6tables -I FORWARD -m geoip --dst-cc CN -j REJECT
        sudo iptables -I OUTPUT -m geoip --dst-cc CN -j REJECT
        sudo ip6tables -I OUTPUT -m geoip --dst-cc CN -j REJECT
        # Log any connection attempts originating from China to '/var/log/kern.log' tagged with the prefix below
        sudo iptables -I INPUT -m geoip --src-cc CN -j LOG --log-prefix '** GFW **'
        sudo ip6tables -I INPUT -m geoip --src-cc CN -j LOG --log-prefix '** GFW **'

        # Save and cleanup
        sudo iptables-save | sudo tee /etc/iptables/rules.v4
        sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

        echo -e "${B_GREEN}\n\nBlocking .cn ccTLD by DNS${RESET}"
        sleep 1
        local IS_CCTLD_DNS_BLOCKED="$(yq '.blocking.clientGroupsBlock.default' ${BLOCKY_CONFIG_FILE} | grep 'cn_cctld')"
        if [ -z "$IS_CCTLD_DNS_BLOCKED" ]; then
            yq '.blocking.clientGroupsBlock.default += "cn_cctld"' ${BLOCKY_CONFIG_FILE} >${BLOCKY_CONFIG_FILE}
        fi
        fn_enable_dns_filtering
        fn_restart_blocky
    else
        echo -e "${B_YELLOW}\n\nNOTICE: xt_geoip module is missing! Reinstalling now, please wait... ${RESET}"
        fn_install_xt_geoip_module
    fi
}

function fn_unblock_china_in_out() {
    echo -e "${B_GREEN}\n\nUnblocking connections to/from China ${RESET}"
    sleep 1

    # Disable logs from any connection attempts originating from China to '/var/log/kern.log' tagged with the prefix below
    sudo iptables -D INPUT -m geoip --src-cc CN -j LOG --log-prefix '** GFW **'
    sudo ip6tables -D INPUT -m geoip --src-cc CN -j LOG --log-prefix '** GFW **'
    # Allow connections to/from China
    sudo iptables -D INPUT -m geoip --src-cc CN -j DROP
    sudo ip6tables -D INPUT -m geoip --src-cc CN -j DROP
    sudo iptables -D FORWARD -m geoip --dst-cc CN -j REJECT
    sudo ip6tables -D FORWARD -m geoip --dst-cc CN -j REJECT
    sudo iptables -D OUTPUT -m geoip --dst-cc CN -j REJECT
    sudo ip6tables -D OUTPUT -m geoip --dst-cc CN -j REJECT

    # Save and cleanup
    sudo iptables-save | sudo tee /etc/iptables/rules.v4
    sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

    echo -e "${B_GREEN}\n\nUnblocking .cn ccTLD by DNS${RESET}"
    sleep 1
    local IS_CCTLD_DNS_BLOCKED="$(yq '.blocking.clientGroupsBlock.default' ${BLOCKY_CONFIG_FILE} | grep 'cn_cctld')"
    if [ ! -z "$IS_CCTLD_DNS_BLOCKED" ]; then
        local IDX=$(yq '.blocking.clientGroupsBlock.default.[] | select(. == "cn_cctld") | path | .[-1]' $BLOCKY_CONFIG_FILE)
        yq "del(.blocking.clientGroupsBlock.default.[$IDX])" ${BLOCKY_CONFIG_FILE} >${BLOCKY_CONFIG_FILE}
    fi
    fn_restart_blocky
}

function fn_toggle_china_blocking() {
    if [ "$BLOCK_CHINA_IN_OUT_STATUS" = "DEACTIVATED" ]; then
        # Install xtables if not found already
        local IS_INSTALLED=$(fn_check_for_pkg xtables-addons-common)
        if [ "$IS_INSTALLED" = false ]; then
            fn_install_xt_geoip_module
        fi
        fn_setup_firewall
        fn_rebuild_xt_geoip_database
        fn_block_china_in_out
    else
        fn_unblock_china_in_out
    fi
}

function fn_update_china_in_out_blocking_status() {
    local IS_MODULE_LOADED=$(lsmod | grep ^xt_geoip)
    if [ ! -z "$IS_MODULE_LOADED" ]; then
        if [ -f "/etc/iptables/rules.v4" ]; then
            local IS_IPTABLES_CONFIGURED=$(cat /etc/iptables/rules.v4 | grep 'INPUT -m geoip --source-country CN  -j DROP')
            if [ "${IS_IPTABLES_CONFIGURED}" ]; then
                BLOCK_CHINA_IN_OUT_STATUS="ACTIVATED"
                BLOCK_CHINA_IN_OUT_STATUS_COLOR=$B_GREEN
            else
                BLOCK_CHINA_IN_OUT_STATUS="DEACTIVATED"
                BLOCK_CHINA_IN_OUT_STATUS_COLOR=$B_RED
            fi
        else
            BLOCK_CHINA_IN_OUT_STATUS="DEACTIVATED"
            BLOCK_CHINA_IN_OUT_STATUS_COLOR=$B_RED
        fi
    else
        BLOCK_CHINA_IN_OUT_STATUS="DEACTIVATED"
        BLOCK_CHINA_IN_OUT_STATUS_COLOR=$B_RED
    fi
}

function fn_block_porn() {
    sudo modprobe xt_geoip
    local IS_MODULE_LOADED=$(lsmod | grep ^xt_geoip)
    if [ ! -z "$IS_MODULE_LOADED" ]; then
        echo -e "${B_GREEN}\n\nBlocking Porn by IP and Payload ${RESET}"
        sleep 1

        # Block by payload match
        for keyword in ${BLOCK_KEYWORDS[@]}; do
            local IS_RULE_IN_EFFECT=$(cat /etc/iptables/rules.v4 | grep $keyword)
            if [ ! "$IS_RULE_IN_EFFECT" ]; then
                sudo iptables -I FORWARD -m string --algo bm --icase --string "$keyword" -j REJECT
                sudo ip6tables -I FORWARD -m string --algo bm --icase --string "$keyword" -j REJECT
            fi
        done

        # Block major porn website IPs
        # Yes! XX stands for Pornland! :P
        sudo iptables -I FORWARD -m geoip --dst-cc XX -j REJECT
        sudo ip6tables -I FORWARD -m geoip --dst-cc XX -j REJECT

        # Save and cleanup
        sudo iptables-save | sudo tee /etc/iptables/rules.v4
        sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

        echo -e "${B_GREEN}\n\nBlocking Porn by DNS${RESET}"
        sleep 1
        local IS_PORN_DNS_BLOCKED="$(yq '.blocking.clientGroupsBlock.default' ${BLOCKY_CONFIG_FILE} | grep 'porn')"
        if [ -z "$IS_PORN_DNS_BLOCKED" ]; then
            yq '.blocking.clientGroupsBlock.default += "porn"' ${BLOCKY_CONFIG_FILE} >${BLOCKY_CONFIG_FILE}
        fi
        fn_enable_dns_filtering
        fn_restart_blocky
    else
        echo -e "${B_YELLOW}\n\nNOTICE: xt_geoip module is missing! Reinstalling now, please wait... ${RESET}"
        fn_install_xt_geoip_module
    fi
}

function fn_unblock_porn() {
    echo -e "${B_GREEN}\n\nUnblocking Porn by IP and Payload${RESET}"
    sleep 1

    # Unblock major porn website IPs
    sudo iptables -D FORWARD -m geoip --dst-cc XX -j REJECT
    sudo ip6tables -D FORWARD -m geoip --dst-cc XX -j REJECT

    # Unblock by payload match
    for keyword in ${BLOCK_KEYWORDS[@]}; do
        local IS_RULE_IN_EFFECT=$(cat /etc/iptables/rules.v4 | grep $keyword)
        if [ "$IS_RULE_IN_EFFECT" ]; then
            sudo iptables -D FORWARD -m string --algo bm --icase --string "$keyword" -j REJECT
            sudo ip6tables -D FORWARD -m string --algo bm --icase --string "$keyword" -j REJECT
        fi
    done

    # Save and cleanup
    sudo iptables-save | sudo tee /etc/iptables/rules.v4
    sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

    echo -e "${B_GREEN}\n\nUnblocking Porn by DNS${RESET}"
    sleep 1
    local IS_PORN_DNS_BLOCKED="$(yq '.blocking.clientGroupsBlock.default' ${BLOCKY_CONFIG_FILE} | grep 'porn')"
    if [ ! -z "$IS_PORN_DNS_BLOCKED" ]; then
        local IDX=$(yq '.blocking.clientGroupsBlock.default.[] | select(. == "porn") | path | .[-1]' $BLOCKY_CONFIG_FILE)
        yq "del(.blocking.clientGroupsBlock.default.[$IDX])" ${BLOCKY_CONFIG_FILE} >${BLOCKY_CONFIG_FILE}
    fi
    fn_restart_blocky
}

function fn_toggle_porn_blocking() {
    if [ "$BLOCK_PORN_STATUS" = "DEACTIVATED" ]; then
        # Install xtables if not found already
        local IS_INSTALLED=$(fn_check_for_pkg xtables-addons-common)
        if [ "$IS_INSTALLED" = false ]; then
            fn_install_xt_geoip_module
        fi
        fn_setup_firewall
        fn_rebuild_xt_geoip_database
        fn_block_porn
    else
        fn_unblock_porn
    fi
}

function fn_update_porn_blocking_status() {
    local IS_MODULE_LOADED=$(lsmod | grep ^xt_geoip)
    if [ ! -z "$IS_MODULE_LOADED" ]; then
        if [ -f "/etc/iptables/rules.v4" ]; then
            local IS_IPTABLES_CONFIGURED=$(cat /etc/iptables/rules.v4 | grep 'FORWARD -m geoip --destination-country XX  -j REJECT')
            if [ "${IS_IPTABLES_CONFIGURED}" ]; then
                BLOCK_PORN_STATUS="ACTIVATED"
                BLOCK_PORN_STATUS_COLOR=$B_GREEN
            else
                BLOCK_PORN_STATUS="DEACTIVATED"
                BLOCK_PORN_STATUS_COLOR=$B_RED
            fi
        else
            BLOCK_PORN_STATUS="DEACTIVATED"
            BLOCK_PORN_STATUS_COLOR=$B_RED
        fi
    else
        BLOCK_PORN_STATUS="DEACTIVATED"
        BLOCK_PORN_STATUS_COLOR=$B_RED
    fi
}

function fn_ac_submenu() {
    # Check and update status variables
    fn_update_iran_outbound_blocking_status
    fn_update_china_in_out_blocking_status
    fn_update_porn_blocking_status
    # Display the menu
    echo -ne "
*** Access Controls ***

${GREEN}1)${RESET} Block OUTGOING connections to Iran and .ir ccTLD:    ${BLOCK_IRAN_OUT_STATUS_COLOR}${BLOCK_IRAN_OUT_STATUS}${RESET}
${GREEN}2)${RESET} Block ALL connections to/from China and .cn ccTLD:   ${BLOCK_CHINA_IN_OUT_STATUS_COLOR}${BLOCK_CHINA_IN_OUT_STATUS}${RESET}
${GREEN}3)${RESET} Block Porn Content:                                  ${BLOCK_PORN_STATUS_COLOR}${BLOCK_PORN_STATUS}${RESET}
${RED}0)${RESET} Return to Main Menu

Choose any option: "
    read -r ans
    case $ans in
    3)
        clear
        fn_toggle_porn_blocking
        clear
        fn_ac_submenu
        ;;
    2)
        clear
        fn_toggle_china_blocking
        clear
        fn_ac_submenu
        ;;
    1)
        clear
        fn_toggle_iran_outbound_blocking
        clear
        fn_ac_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_ac_submenu
        ;;
    esac
}
