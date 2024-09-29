source $PWD/src/shell/base/colors.sh

if [ -f /var/run/reboot-required ]; then
    echo -e "${B_RED}\n\nReboot required! Your server is now going to reboot to load new changes! ${RESET}"
    echo -e "${B_BLUE}After booting up, run the script again with the following commands to proceed!${RESET}"
    echo -e "${B_YELLOW}cd Rainb0w"
    echo -e "./run.sh${RESET}"
    systemctl reboot
    exit
fi
