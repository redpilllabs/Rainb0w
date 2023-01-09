#!/bin/bash

DISTRO="$(awk -F= '/^NAME/{print $2}' /etc/os-release)"
DISTRO_VERSION=$(echo "$(awk -F= '/^VERSION_ID/{print $2}' /etc/os-release)" | tr -d '"')
MON=$(date +"%m")
YR=$(date +"%Y")

if [ "$DISTRO_VERSION" == "20.04" ]; then
    echo -e "${RED}xt_geoip module on Ubuntu 20.04 needs MaxMind database which is no longer available without a license! You need to upgrade to 22.04!"
    exit 0
fi

if [ "$(lsmod | grep ^xt_geoip)" ]; then
    # Download the latest GeoIP database
    MON=$(date +"%m")
    YR=$(date +"%Y")
    if [ ! -d "/usr/share/xt_geoip" ]; then
        sudo mkdir /usr/share/xt_geoip
    fi

    sudo curl -s "https://download.db-ip.com/free/dbip-country-lite-${YR}-${MON}.csv.gz" >/usr/share/xt_geoip/dbip-country-lite-$YR-$MON.csv.gz
    sudo gunzip /usr/share/xt_geoip/dbip-country-lite-$YR-$MON.csv.gz

    # Convert CSV database to binary format for xt_geoip
    sudo /usr/libexec/xtables-addons/xt_geoip_build -s -i /usr/share/xt_geoip/dbip-country-lite-$YR-$MON.csv

    # Load xt_geoip kernel module
    modprobe xt_geoip

    # Cleanup
    sudo rm /usr/share/xt_geoip/dbip-country-lite-$YR-$MON.csv
fi
