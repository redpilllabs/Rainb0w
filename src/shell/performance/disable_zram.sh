#!/bin/bash
source $PWD/src/shell/base/colors.sh

echo -e "${B_GREEN}>> Disabling ZRam swap ${RESET}"
systemctl disable --now zramswap.service
