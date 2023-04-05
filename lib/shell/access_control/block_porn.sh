#!/bin/bash
source $PWD/lib/shell/base/colors.sh

modprobe xt_geoip
IS_MODULE_LOADED=$(lsmod | grep ^xt_geoip)
if [ ! -z "$IS_MODULE_LOADED" ]; then
    bash $PWD/lib/shell/os/install_xt_geoip.sh
fi

echo -e "${B_GREEN}>> Block Porn by IP ${RESET}"

# Block major porn website IPs
iptables -I FORWARD -m geoip --dst-cc XX -m comment --comment "Block Porn" -j REJECT
ip6tables -I FORWARD -m geoip --dst-cc XX -m comment --comment "Block Porn" -j REJECT
iptables -A OUTPUT -m geoip --dst-cc XX -m comment --comment "Block Porn" -j REJECT
ip6tables -A OUTPUT -m geoip --dst-cc XX -m comment --comment "Block Porn" -j REJECT

# Save changes
iptables-save | tee /etc/iptables/rules.v4 >/dev/null
ip6tables-save | tee /etc/iptables/rules.v6 >/dev/null
