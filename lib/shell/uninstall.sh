#!/bin/bash
source $PWD/lib/shell/base/colors.sh

echo -e "${B_GREEN}>> Stopping and removing Docker containers${RESET}"
docker ps -aq | xargs docker stop | xargs docker rm
docker network remove caddy
docker volume remove sockets
docker volume remove wordpress_db
docker volume remove wordpress_blog
docker volume remove wordpress_apache2
docker image rm wordpress
echo -e "${B_GREEN}>> Removing files${RESET}"
rm -rf $HOME/Rainb0w_Home

# Resetting policies to avoid getting locked out until changes are saved!
echo -e "${B_GREEN}>> Resetting firewall${RESET}"
iptables -P INPUT ACCEPT
ip6tables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
ip6tables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
ip6tables -P OUTPUT ACCEPT
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
systemctl restart docker

# Save changes
iptables-save | tee /etc/iptables/rules.v4 >/dev/null
ip6tables-save | tee /etc/iptables/rules.v6 >/dev/null

echo -e "${B_GREEN}>> Resetting DNS settings${RESET}"
rm /etc/systemd/resolved.conf.d/nostublistener.conf
rm /etc/resolv.conf
mv /etc/resolv.conf.backup /etc/resolv.conf
systemctl reload-or-restart systemd-resolved

echo -e "${B_GREEN}<< Finished uninstallation! >>${RESET}"
