#!/bin/bash
source $PWD/lib/shell/base/colors.sh
source $PWD/lib/shell/os/os_utils.sh

echo -e "${B_GREEN}>> Installing required packages for ZRam swap ${RESET}"
fn_check_and_install_pkg linux-modules-extra-$(uname -r)
fn_check_and_install_pkg zram-tools

echo -e "${B_GREEN}>> Enabling ZRam swap to optimize memory ${RESET}"
echo "ALGO=zstd" | tee /etc/default/zramswap >/dev/null
echo "PERCENT=50" | tee -a /etc/default/zramswap >/dev/null
systemctl enable zramswap.service
systemctl restart zramswap.service
