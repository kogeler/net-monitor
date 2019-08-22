#!/bin/bash

dir_scripts='/opt/net-monitor/'
dir_ram='/media/ram1/wireshark/'
dir_raw_mobile="$dir_ram"'raw-mobile/'

int_TERM ()
{

	pkill -TERM -P "$$" &>> /dev/null
	exit 1

}

trap int_TERM 15

if [ ! -d "$dir_ram" ]
then

	mkdir -m 777 "$dir_ram" &>> /dev/null

fi

if [ -d "$dir_raw_mobile" ]
then

	find "$dir_raw_mobile" -maxdepth 1 -type f -delete &>> /dev/null

else

	mkdir -m 777 "$dir_raw_mobile" &>> /dev/null

fi

tshark -i br0 -p -B 1024 -f 'ip proto 0x84' -b filesize:204800 -F pcapng -w "$dir_raw_mobile"'dump' &>> /dev/null &
WS_PID=$!

while [ 1 ]
do

	sleep 10

	if [ $(ps "$WS_PID" | wc -l) -eq '1' ]
	then
		echo 'RESET'
		pkill -TERM -P "$$" &>> /dev/null
		find "$dir_raw_mobile" -maxdepth 1 -type f -delete &>> /dev/null
		tshark -i br0 -p -B 1024 -f 'ip proto 0x84' -b filesize:204800 -F pcapng -w "$dir_raw_mobile"'dump' &>> /dev/null &
		WS_PID=$!		
	fi

done
