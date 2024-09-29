#!/bin/bash

trap - INT
# Update OS
echo -e "${B_GREEN}>> Updating the operating system ${RESET}"
apt update
apt upgrade -y
