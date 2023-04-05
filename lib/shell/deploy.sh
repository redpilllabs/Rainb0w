#!/bin/bash
source $PWD/lib/shell/base/colors.sh
source $PWD/lib/shell/os/os_utils.sh
source $PWD/lib/shell/docker/docker_utils.sh

# Install Docker and required packages
fn_check_and_install_pkg curl
fn_check_and_install_pkg bc
fn_check_and_install_pkg logrotate
fn_check_and_install_pkg iptables-persistent
source $PWD/lib/shell/os/install_docker.sh
source $PWD/lib/shell/docker/init_vol_net.sh
source $PWD/lib/shell/os/install_xt_geoip.sh

CONTAINERS=($(ls -d "$HOME/Rainb0w_Home/"*/ | sed 's;^'"$HOME/Rainb0w_Home/"'\(.*\)/;\1;' | sed '/^caddy$/d'))

# Activate necessary protections
is_free_domain_tld=$(
    python3 $PWD/lib/post-deploy/get_domain_type.py "$HOME/Rainb0w_Home/rainb0w_config.toml"
)
if [ "$is_free_domain_tld" == "True" ]; then
    source $PWD/lib/shell/access_control/setup_firewall.sh "free_tld"
elif [ "$is_free_domain_tld" == "False" ]; then
    # If using a non-free domain, your server can enojy even better protection
    source $PWD/lib/shell/access_control/setup_firewall.sh "paid_tld"
fi

# Apply Kernel's network stack optimizations in Express mode
if [ ! $# -eq 0 ]; then
    if [ "$1" == 'Express' ]; then
        source $PWD/lib/shell/performance/tune_kernel_net.sh
    fi
fi

if [[ " ${CONTAINERS[@]} " =~ "hysteria" ]]; then
    # Get Hysteria port range from the rainb0w_config.toml and allow them in iptables
    data=$(python3 $PWD/lib/post-deploy/get_hysteria_port_range.py "$HOME/Rainb0w_Home/rainb0w_config.toml")
    range_start=$(echo $data | awk -F'[ :]' '{print $4}')
    range_end=$(echo $data | awk -F'[ :]' '{print $8}')
    source $PWD/lib/shell/os/open_hysteria_ports.sh $range_start $range_end
fi

# Build a Docker image for Caddy and check if the image was successfully built
if [ ! "$(docker images -q caddy)" ]; then
    docker buildx build --tag caddy $HOME/Rainb0w_Home/caddy/
    if [ ! "$(docker images -q caddy)" ]; then
        echo -e "${B_RED}There was an issue when building a Docker image for 'Caddy', check the logs!${RESET}"
        echo -e "${B_YELLOW}After resolving the issue, run the installer again.${RESET}"
        rm -rf $HOME/Rainb0w_Home
        exit
    fi
fi

MEMORY_SIZE=$(free -m | awk '/Mem:/ { print $2 }')
if [ $MEMORY_SIZE -gt 512 ]; then
    # Build a Docker image for WordPress and check if the image was successfully built
    if [ ! "$(docker images -q wordpress)" ]; then
        docker buildx build --tag wordpress $HOME/Rainb0w_Home/wordpress/
        if [ ! "$(docker images -q wordpress)" ]; then
            echo -e "${B_RED}There was an issue when building a Docker image for 'WordPress', check the logs!${RESET}"
            echo -e "${B_YELLOW}After resolving the issue, run the installer again.${RESET}"
            rm -rf $HOME/Rainb0w_Home
            exit
        fi
    fi
else
    echo -e "${B_RED}Memory is insufficient to run a WordPress container, consider upgrading your server specs!"
    CONTAINERS=$(echo "$CONTAINERS" | sed 's/wordpress//g')
fi

if [[ " ${CONTAINERS[@]} " =~ "mtprotopy" ]]; then
    # Build a Docker image for MTProtoPy and check if the image was successfully buil
    if [ ! "$(docker images -q mtprotopy)" ]; then
        docker buildx build --tag mtprotopy $HOME/Rainb0w_Home/mtprotopy/
        if [ ! "$(docker images -q mtprotopy)" ]; then
            echo -e "${B_RED}There was an issue when building a Docker image for 'MTProtoPy', check the logs!${RESET}"
            echo -e "${B_YELLOW}After resolving the issue, run the installer again.${RESET}"
            rm -rf $HOME/Rainb0w_Home
            exit
        fi
    fi
fi

# Disable DNS stub listener to free up the port 53
source $PWD/lib/shell/os/disable_dns_stub_listener.sh

# Start proxy containers one by one but start off with Caddy to get TLS certs
fn_restart_docker_container "caddy"
for proxy in ${CONTAINERS[@]}; do
    fn_restart_docker_container $proxy
done

echo -e "\nWordPress admin area credentials:"
WP_ADMIN=$(grep -w 'WORDPRESS_ADMIN_USER' $HOME/Rainb0w_Home/wordpress/wp.env | cut -d= -f2)
WP_ADMIN=${WP_ADMIN//\'/}
WP_PASSWORD=$(grep -w 'WORDPRESS_ADMIN_PASSWORD' $HOME/Rainb0w_Home/wordpress/wp.env | cut -d= -f2)
WP_PASSWORD=${WP_PASSWORD//\'/}
echo -e "WP Admin URL:  ${B_BLUE}https://YOUR_MAIN_DOMAIN/wp-admin ${RESET}"
echo -e "WP Username:   ${B_GREEN}$WP_ADMIN${RESET}"
echo -e "WP Password:   ${B_GREEN}$WP_PASSWORD${RESET}"

echo -e "\n\nYour proxies are ready now!\n"

if [ ! $# -eq 0 ]; then
    if [ "$1" == 'Express' ]; then
        python3 $PWD/lib/post-deploy/get_client_url.py "$HOME/Rainb0w_Home/rainb0w_config.toml" "$HOME/Rainb0w_Home/rainb0w_users.toml" "Rainb0w"
    elif [ "$1" == 'Custom' ]; then
        username=$(python3 $PWD/lib/post-deploy/get_first_username.py "$HOME/Rainb0w_Home/rainb0w_users.toml")
        python3 $PWD/lib/post-deploy/get_client_url.py "$HOME/Rainb0w_Home/rainb0w_config.toml" "$HOME/Rainb0w_Home/rainb0w_users.toml" $username
    elif [ "$1" == 'Restore' ]; then
        echo -e "User share urls are the same as in your configuration, you can view them in the dashboard"
    else
        echo -e "Invalid mode supplied!"
    fi
fi

echo -e "\nYou can add/remove users or find more options in the dashboard,
in order to display the dashboard run the 'menu.sh' again."
