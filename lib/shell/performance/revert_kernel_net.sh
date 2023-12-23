#!/bin/bash
source $PWD/lib/shell/base/colors.sh

echo -e "${B_GREEN}>> Rolling back Kernel parameters ${RESET}"
if [ "$(sysctl -n net.ipv4.tcp_congestion_control)" = "bbr" ]; then
    if [ -f "/etc/sysctl.d/99-x-network-tune.conf" ]; then
        rm /etc/sysctl.d/99-x-network-tune.conf
    fi
    # Default values from Ubuntu 22.04
    sysctl net.ipv4.tcp_congestion_control=cubic
    sysctl net.core.default_qdisc=fq_codel
    sysctl net.ipv4.tcp_notsent_lowat=4294967295
    sysctl net.ipv4.tcp_slow_start_after_idle=1
    sysctl net.core.rmem_max=212992
    sysctl net.core.wmem_max=212992
    sysctl --system
fi
sleep 1
