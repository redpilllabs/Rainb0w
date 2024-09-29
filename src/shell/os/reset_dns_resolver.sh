#!/bin/bash

# This script tries to reset the system DNS resolver to Cloudflare
# and it's only executed if there issues with DNS name resolutions
echo "DNS=1.1.1.1" | tee /etc/systemd/resolved.conf
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl restart systemd-resolved
