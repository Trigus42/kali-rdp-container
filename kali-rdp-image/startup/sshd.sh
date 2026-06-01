#!/usr/bin/env bash

if [[ ${SSHD_ENABLE} == 'true' ]]
then
	# Set up authorized_keys for kali user from mounted secret
	if [[ -f /etc/ssh/authorized_keys/authorized_keys ]]; then
		mkdir -p /home/kali/.ssh
		cp /etc/ssh/authorized_keys/authorized_keys /home/kali/.ssh/authorized_keys
		chmod 700 /home/kali/.ssh
		chmod 600 /home/kali/.ssh/authorized_keys
		chown -R kali:kali /home/kali/.ssh
	fi

	/usr/sbin/sshd -D -e
fi
