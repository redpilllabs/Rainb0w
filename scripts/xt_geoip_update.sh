#!/bin/bash

DISTRO="$(awk -F= '/^NAME/{print $2}' /etc/os-release)"
DISTRO_VERSION=$(echo "$(awk -F= '/^VERSION_ID/{print $2}' /etc/os-release)" | tr -d '"')
MON=$(date +"%m")
YR=$(date +"%Y")

if [ "$(lsmod | grep ^xt_geoip)" ]; then
    # Download the latest GeoIP database
    sudo mkdir /usr/share/xt_geoip
    sudo wget "https://download.db-ip.com/free/dbip-country-lite-${YR}-${MON}.csv.gz" -O /usr/share/xt_geoip/dbip-country-lite.csv.gz
    sudo gunzip /usr/share/xt_geoip/dbip-country-lite.csv.gz
    # Convert CSV database to binary format for xt_geoip
    if [[ "$DISTRO" =~ "Ubuntu" ]]; then
        if (($(echo "$DISTRO_VERSION == 20.04" | bc -l))); then
            sudo /usr/lib/xtables-addons/xt_geoip_build -D /usr/share/xt_geoip/ -S /usr/share/xt_geoip/
        elif (($(echo "$DISTRO_VERSION == 22.04" | bc -l))); then
            sudo /usr/libexec/xtables-addons/xt_geoip_build -s -i /usr/share/xt_geoip/dbip-country-lite.csv.gz
        fi
    elif [[ "$DISTRO" =~ "Debian GNU/Linux" ]]; then
        if (($(echo "$DISTRO_VERSION == 11" | bc -l))); then
            sudo /usr/libexec/xtables-addons/xt_geoip_build -s -i /usr/share/xt_geoip/dbip-country-lite.csv.gz
        fi
    fi

    # Load xt_geoip kernel module
    modprobe xt_geoip

    # Cleanup
    sudo rm /usr/share/xt_geoip/dbip-country-lite.csv
fi
