if [[ ${MSF_ENABLE} == 'true' ]]
then
	service postgresql start
	msfdb init
fi