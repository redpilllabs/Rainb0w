#!/bin/bash
source $PWD/lib/shell/base/colors.sh
source $PWD/lib/shell/os/os_utils.sh

IS_PKG_INSTALLED=$(fn_check_for_pkg xtables-addons-dkms)
if [ "$IS_PKG_INSTALLED" = false ] || [ ! -d "/usr/libexec/rainb0w" ]; then
    echo -e "${B_GREEN}>> Installing xt_geoip module${RESET}"
    fn_check_and_install_pkg xtables-addons-dkms
    fn_check_and_install_pkg xtables-addons-common
    fn_check_and_install_pkg libtext-csv-xs-perl
    fn_check_and_install_pkg libmoosex-types-netaddr-ip-perl
    fn_check_and_install_pkg pkg-config
    fn_check_and_install_pkg iptables-persistent
    fn_check_and_install_pkg cron
    fn_check_and_install_pkg curl

    # Build the IP database
    source $PWD/lib/shell/os/rebuild_xt_geoip_db.sh

    # Rotate kernel logs and limit them to max 100MB
    source $PWD/lib/shell/os/enable_kernel_logrotate.sh

    # Add cronjob to keep the database updated
    systemctl enable --now cron
    if [ ! -f "/etc/crontab" ]; then
        touch /etc/crontab
    fi
    if ! crontab -l | grep -q "0 1 * * * root bash /usr/libexec/rainb0w/xt_geoip_update.sh >/tmp/xt_geoip_update.log"; then
        echo -e "${B_GREEN}>> Adding cronjob to update xt_goip database \n  ${RESET}"
        cp $PWD/lib/shell/os/xt_geoip_update.sh /usr/libexec/rainb0w/xt_geoip_update.sh
        chmod +x /usr/libexec/rainb0w/xt_geoip_update.sh
        # Check for updates daily
        (
            crontab -l
            echo "0 1 * * * root bash /usr/libexec/rainb0w/xt_geoip_update.sh >/tmp/xt_geoip_update.log"
        ) | crontab -
    fi

    service netfilter-persistent restart
fi
