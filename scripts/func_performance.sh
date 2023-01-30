#!/bin/bash

function fn_tune_kernel() {
    echo -e "${B_GREEN}Tuning the network stack for best performance${RESET}"
    if [ ! -d "/etc/sysctl.d" ]; then
        sudo mkdir -p /etc/sysctl.d
    fi
    if [ -f "/etc/sysctl.d/99-x-network-tune.conf" ]; then
        sudo rm /etc/sysctl.d/99-x-network-tune.conf
        sudo touch /etc/sysctl.d/99-x-network-tune.conf
    fi
    # Optimizations recommended from [https://blog.cloudflare.com/http-2-prioritization-with-nginx/]
    echo -e "${GREEN}Tuning TCP with BBR and fq ${RESET}"
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.d/99-x-network-tune.conf
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.d/99-x-network-tune.conf
    echo "net.ipv4.tcp_notsent_lowat=16384" | sudo tee -a /etc/sysctl.d/99-x-network-tune.conf
    echo "net.ipv4.tcp_slow_start_after_idle=0" | sudo tee -a /etc/sysctl.d/99-x-network-tune.conf
    # UDP optimizations
    echo -e "${GREEN}Tuning UDP buffer size ${RESET}"
    echo "net.core.rmem_max=4000000" | sudo tee -a /etc/sysctl.d/99-x-network-tune.conf
    echo "net.core.wmem_max=4000000" | sudo tee -a /etc/sysctl.d/99-x-network-tune.conf
    sudo sysctl -p /etc/sysctl.d/99-x-network-tune.conf
    echo -e "${B_GREEN}<<< Finished kernel tuning! >>> ${RESET}"
    sleep 1
}

function fn_rollback_kernel_tuning() {
    echo -e "${B_GREEN}Rolling back Kernel parameters ${RESET}"
    if [ "$(sysctl -n net.ipv4.tcp_congestion_control)" = "bbr" ]; then
        if [ -f "/etc/sysctl.d/99-x-network-tune.conf" ]; then
            sudo rm /etc/sysctl.d/99-x-network-tune.conf
        fi
        # Default values from Ubuntu 22.04
        sudo sysctl net.ipv4.tcp_congestion_control=cubic
        sudo sysctl net.core.default_qdisc=fq_codel
        sudo sysctl net.ipv4.tcp_notsent_lowat=4294967295
        sudo sysctl net.ipv4.tcp_slow_start_after_idle=1
        sudo sysctl net.core.rmem_max=212992
        sudo sysctl net.core.wmem_max=212992
        sudo sysctl --system
    fi
    echo -e "${B_GREEN}<<< Finished rollback! >>> ${RESET}"
    sleep 1
}

function fn_enable_zram() {
    trap - INT
    echo -e "${B_GREEN}Installing required packages for ZRam swap ${RESET}"
    fn_check_and_install_pkg zram-tools linux-modules-extra-$(uname -r)
    fn_check_and_install_pkg linux-modules-extra-$(uname -r)

    echo -e "${B_GREEN}Enabling ZRam swap to optimize memory ${RESET}"
    echo "ALGO=zstd" | sudo tee /etc/default/zramswap
    echo "PERCENT=50" | sudo tee -a /etc/default/zramswap
    sudo systemctl enable zramswap.service
    sudo systemctl restart zramswap.service
}

function fn_disable_zram() {
    echo -e "${B_GREEN}Disabling ZRam swap ${RESET}"
    sudo systemctl disable --now zramswap.service
}

function fn_toggle_kernel_tuning() {
    if [ "$KERNEL_TUNING_STATUS" = "DEACTIVATED" ]; then
        fn_tune_kernel
    else
        fn_rollback_kernel_tuning
    fi
}

function fn_toggle_zram_swap() {
    if [ "$ZRAM_STATUS" = "DEACTIVATED" ]; then
        fn_enable_zram
    else
        fn_disable_zram
    fi
}

function fn_update_kernel_tuning_status() {
    local TCP_CONGESTION_CONTROL=$(sysctl -n net.ipv4.tcp_congestion_control)
    if [ "$TCP_CONGESTION_CONTROL" = "bbr" ]; then
        KERNEL_TUNING_STATUS="ACTIVATED"
        KERNEL_TUNING_STATUS_COLOR=$B_GREEN
    else
        KERNEL_TUNING_STATUS="DEACTIVATED"
        KERNEL_TUNING_STATUS_COLOR=$B_RED
    fi
}

function fn_update_zram_status() {
    local IS_ZRAM_ACTIVE=$(cat /proc/swaps | grep zram)
    if [ ! -z "$IS_ZRAM_ACTIVE" ]; then
        ZRAM_STATUS="ACTIVATED"
        ZRAM_STATUS_COLOR=$B_GREEN
    else
        ZRAM_STATUS="DEACTIVATED"
        ZRAM_STATUS_COLOR=$B_RED
    fi
}

function fn_performance_submenu() {
    # Check and update status variables
    fn_update_kernel_tuning_status
    fn_update_zram_status
    # Display the menu
    echo -ne "
*** ${MAGENTA}Performance Settings${RESET} ***

${GREEN}1)${RESET} Tune Kernel Parameters (BBR):    ${KERNEL_TUNING_STATUS_COLOR}${KERNEL_TUNING_STATUS}${RESET}
${GREEN}2)${RESET} Optimize Memory with Zram:       ${ZRAM_STATUS_COLOR}${ZRAM_STATUS}${RESET}
${RED}0)${RESET} Return to Main Menu

Choose any option: "
    read -r ans
    case $ans in
    2)
        clear
        fn_toggle_zram_swap
        clear
        fn_performance_submenu
        ;;
    1)
        clear
        fn_toggle_kernel_tuning
        clear
        fn_performance_submenu
        ;;
    0)
        clear
        mainmenu
        ;;
    *)
        fn_fail
        clear
        fn_performance_submenu
        ;;
    esac
}
