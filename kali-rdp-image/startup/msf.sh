#!/usr/bin/env bash

if [[ ${MSF_ENABLE} == 'true' ]]
then
	service postgresql start
	msfdb init
else
	echo "MSF_ENABLE is not set to 'true'. Skipping Metasploit Framework startup."
fi

exit 0