#!/bin/bash
source $PWD/src/shell/base/colors.sh

if [ ! -d "/etc/sysctl.d" ]; then
    mkdir -p /etc/sysctl.d
fi
if [ -f "/etc/sysctl.d/99-x-network-tune.conf" ]; then
    rm /etc/sysctl.d/99-x-network-tune.conf
    touch /etc/sysctl.d/99-x-network-tune.conf
fi
# Optimizations recommended from [https://blog.cloudflare.com/http-2-prioritization-with-nginx/]
echo -e "${B_GREEN}>> Tuning TCP stack with BBR and fq ${RESET}"
echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.d/99-x-network-tune.conf >/dev/null
echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.d/99-x-network-tune.conf >/dev/null
echo "net.ipv4.tcp_notsent_lowat=16384" | tee -a /etc/sysctl.d/99-x-network-tune.conf >/dev/null
echo "net.ipv4.tcp_slow_start_after_idle=0" | tee -a /etc/sysctl.d/99-x-network-tune.conf >/dev/null
# UDP optimizations
echo -e "${B_GREEN}>> Tuning UDP buffer size ${RESET}"
echo "net.core.rmem_max=4000000" | tee -a /etc/sysctl.d/99-x-network-tune.conf >/dev/null
echo "net.core.wmem_max=4000000" | tee -a /etc/sysctl.d/99-x-network-tune.conf >/dev/null
sysctl -p /etc/sysctl.d/99-x-network-tune.conf
sleep 1
