#!/bin/bash
source $PWD/lib/shell/base/colors.sh

echo -e "${B_GREEN}>> Disabling ZRam swap ${RESET}"
systemctl disable --now zramswap.service
