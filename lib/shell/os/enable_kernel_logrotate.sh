#!/bin/bash
source $PWD/lib/shell/base/colors.sh

# This helps avoiding an ever-increasing large .log file by
# breaking down the log files into smaller ones and
# removing the oldest one when it reaches a certain threshold

if [ ! -f "/etc/logrotate.d/kernel" ]; then
	# Remove kern.log from rsyslog since we're going to modify its settings
	sed -i 's!/var/log/kern.log!!g' /etc/logrotate.d/rsyslog
	sed -i '/^\s*$/d' /etc/logrotate.d/rsyslog
	touch /etc/logrotate.d/kernel
	sh -c 'echo "/var/log/kern.log
{
	size 20M
    rotate 5
    copytruncate
	missingok
	notifempty
	compress
	delaycompress
	sharedscripts
	postrotate
		/usr/lib/rsyslog/rsyslog-rotate
	endscript
}" > /etc/logrotate.d/kernel'
fi
