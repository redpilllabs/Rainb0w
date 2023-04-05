#!/bin/bash
source $PWD/lib/shell/base/colors.sh

echo -e "${B_GREEN}>> Unblock Porn by IP ${RESET}"

# Unblock major porn website IPs
iptables -D FORWARD -m geoip --dst-cc XX -m comment --comment "Block Porn" -j REJECT
ip6tables -D FORWARD -m geoip --dst-cc XX -m comment --comment "Block Porn" -j REJECT
iptables -D OUTPUT -m geoip --dst-cc XX -m comment --comment "Block Porn" -j REJECT
ip6tables -D OUTPUT -m geoip --dst-cc XX -m comment --comment "Block Porn" -j REJECT

# Save changes
iptables-save | tee /etc/iptables/rules.v4 >/dev/null
ip6tables-save | tee /etc/iptables/rules.v6 >/dev/null
