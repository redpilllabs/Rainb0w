#!/bin/bash
source $PWD/lib/shell/base/colors.sh
source $PWD/lib/shell/base/config.sh

echo -e "${B_GREEN}>> Opening port range $1-$2 for Hysteria connections ${RESET}"
# Redirect traffic from the port range to Hysteria's listening port
iptables -t nat -A PREROUTING -p udp --dport $1:$2 -j DNAT --to-destination :4443
ip6tables -t nat -A PREROUTING -p udp --dport $1:$2 -j DNAT --to-destination :4443
# Allow traffic from the port range requested
iptables -A INPUT -p udp --dport $1:$2 -j ACCEPT
ip6tables -A INPUT -p udp --dport $1:$2 -j ACCEPT

# Save changes
iptables-save | tee /etc/iptables/rules.v4 >/dev/null
ip6tables-save | tee /etc/iptables/rules.v6 >/dev/null
