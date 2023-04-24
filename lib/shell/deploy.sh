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

# Apply Kernel's network stack optimizations
source $PWD/lib/shell/performance/tune_kernel_net.sh

# Activate necessary protections
is_free_domain_tld=$(
    python3 $PWD/lib/shell/helper/get_domain_type.py
)
if [ "$is_free_domain_tld" == "True" ]; then
    source $PWD/lib/shell/access_control/setup_firewall.sh "free_tld"
elif [ "$is_free_domain_tld" == "False" ]; then
    # If using a non-free domain, your server can enojy even better protection
    source $PWD/lib/shell/access_control/setup_firewall.sh "paid_tld"
fi

python3 $PWD/lib/shell/helper/get_proxy_status.py "hysteria"
PYTHON_EXIT_CODE=$?
if [ $PYTHON_EXIT_CODE -ne 0 ]; then
    # Get Hysteria port range from the rainb0w_config.toml and allow them in iptables
    data=$(python3 $PWD/lib/shell/helper/get_hysteria_port_range.py)
    range_start=$(echo $data | awk -F'[ :]' '{print $4}')
    range_end=$(echo $data | awk -F'[ :]' '{print $8}')
    source $PWD/lib/shell/access_control/open_hysteria_port_range.sh $range_start $range_end
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

# Start off with Caddy since we need TLS certs
fn_restart_docker_container "caddy"
sleep 10

# Disable DNS stub listener to free up the port 53 for blocky
source $PWD/lib/shell/os/disable_dns_stub_listener.sh
python3 $PWD/lib/shell/helper/get_proxy_status.py "dot_doh"
PYTHON_EXIT_CODE=$?
if [ $PYTHON_EXIT_CODE -ne 0 ]; then
    source $PWD/lib/shell/access_control/allow_port.sh "DoT" 853 "tcp"
    source $PWD/lib/shell/access_control/allow_port.sh "DoQ" 853 "udp"
fi
# Start blocky since we need DNS
fn_restart_docker_container "blocky"

python3 $PWD/lib/shell/helper/get_proxy_status.py "xray"
PYTHON_EXIT_CODE=$?
if [ $PYTHON_EXIT_CODE -ne 0 ]; then
    fn_restart_docker_container "xray"
fi

python3 $PWD/lib/shell/helper/get_proxy_status.py "hysteria"
PYTHON_EXIT_CODE=$?
if [ $PYTHON_EXIT_CODE -ne 0 ]; then
    fn_restart_docker_container "hysteria"
fi

python3 $PWD/lib/shell/helper/get_proxy_status.py "mtprotopy"
PYTHON_EXIT_CODE=$?
if [ $PYTHON_EXIT_CODE -ne 0 ]; then
    fn_restart_docker_container "mtprotopy"
fi

if [ $MEMORY_SIZE -gt 512 ]; then
    fn_restart_docker_container "wordpress"
    echo -e "\nWordPress admin area credentials:"
    WP_ADMIN=$(grep -w 'WORDPRESS_ADMIN_USER' $HOME/Rainb0w_Home/wordpress/wp.env | cut -d= -f2)
    WP_ADMIN=${WP_ADMIN//\'/}
    WP_PASSWORD=$(grep -w 'WORDPRESS_ADMIN_PASSWORD' $HOME/Rainb0w_Home/wordpress/wp.env | cut -d= -f2)
    WP_PASSWORD=${WP_PASSWORD//\'/}
    echo -e "WP Admin URL:  ${B_BLUE}https://YOUR_MAIN_DOMAIN/wp-admin ${RESET}"
    echo -e "WP Username:   ${B_GREEN}$WP_ADMIN${RESET}"
    echo -e "WP Password:   ${B_GREEN}$WP_PASSWORD${RESET}"
fi

echo -e "\n\nYour proxies are ready now!\n"

if [ ! $# -eq 0 ]; then
    if [ "$1" == 'Install' ]; then
        username=$(python3 $PWD/lib/shell/helper/get_first_username.py)
        python3 $PWD/lib/shell/helper/get_client_url.py $username
    elif [ "$1" == 'Restore' ]; then
        echo -e "User share urls are the same as in your configuration, you can view them in the dashboard"
    else
        echo -e "Invalid mode supplied!"
    fi
fi

echo -e "\nYou can add/remove users or find more options in the dashboard,
in order to display the dashboard run the 'menu.sh' again."
