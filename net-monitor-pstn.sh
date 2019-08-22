#!/bin/bash

dir_scripts='/opt/net-monitor/'
dir_ram='/media/ram1/wireshark/'
dir_raw_pstn="$dir_ram"'raw-pstn/'

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

if [ -d "$dir_raw_pstn" ]
then

	find "$dir_raw_pstn" -maxdepth 1 -type f -delete &>> /dev/null

else

	mkdir -m 777 "$dir_raw_pstn" &>> /dev/null

fi

sshpass -p 'iskratel' ssh root@10.24.224.131 'tcpdump -i bond0.104 -s 0 -U -w -' 2>> /dev/null | tshark -i - -B 1024 -b duration:600 -F pcapng -w "$dir_raw_pstn"'vlg' &>> /dev/null &
WS_VLG_PID=$!

sshpass -p 'iskratel' ssh root@10.24.226.131 'tcpdump -i bond0.104 -s 0 -U -w -' 2>> /dev/null | tshark -i - -B 1024 -b duration:600 -F pcapng -w "$dir_raw_pstn"'chr' &>> /dev/null &
WS_CHR_PID=$!

while [ 1 ]
do

	sleep 10

	if [ $(ps "$WS_VLG_PID" | wc -l) -eq '1' ]
	then
		echo 'RESET'
#		find "$dir_raw_pstn" -maxdepth 1 -type f -delete &>> /dev/null
		sshpass -p 'iskratel' ssh root@10.24.224.131 'tcpdump -i bond0.104 -s 0 -U -w -' 2>> /dev/null | tshark -i - -B 1024 -b duration:600 -F pcapng -w "$dir_raw_pstn"'vlg' &>> /dev/null &
		WS_VLG_PID=$!		
	fi

	if [ $(ps "$WS_CHR_PID" | wc -l) -eq '1' ]
        then
                echo 'RESET'
#                find "$dir_raw_pstn" -maxdepth 1 -type f -delete &>> /dev/null
                sshpass -p 'iskratel' ssh root@10.24.226.131 'tcpdump -i bond0.104 -s 0 -U -w -' 2>> /dev/null | tshark -i - -B 1024 -b duration:600 -F pcapng -w "$dir_raw_pstn"'chr' &>> /dev/null &
                WS_CHR_PID=$!
        fi


done
