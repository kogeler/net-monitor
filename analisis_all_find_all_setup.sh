#!/bin/bash

dir_lzma='/media/data/wireshark/'
dir_lzma_mobile_radio="$dir_lzma"'lzma-mobile-radio/'

dir_ram='/media/ram1/wireshark/'
dir_unlzma="$dir_ram"'unlzma/'
dir_unlzma_lock="$dir_ram"'unlzma-lock/'
dir_result="$dir_ram"'result/'

touch "$dir_unlzma_lock"$2 &>> /dev/null

7z x "$dir_lzma_mobile_radio"$2 -o"$dir_unlzma" &>> /dev/null

num='0'
TIME_P='0'
c_f_s='0'
c_index='0'
s_index='1'

temp=$(tshark -V -t ad -Y "gsm_a.dtap.msg_cc_type == 0x05" -r "$dir_unlzma"${2:0:14} 2>/dev/null)
c_f_s=$(echo "$temp" | grep -c -e "Called Party BCD Number")

if [ $c_f_s -gt '0' ]
then

#	echo "$temp"

	f_s=$(echo "$temp" | grep -n -e "Called Party BCD Number")

#	echo "${2:0:14}" "$f_s"
#	echo "$temp" | sed -n $n_s'p'

fi

while [ $c_index -lt $c_f_s ]
do

	let c_index++

#	echo "${2:0:14}" 'S: ' $(echo "$f_s" | sed -n $c_index'p')

	num=$(echo "$f_s" | sed -n $c_index'p' | awk '{print $7}')
	echo "$num" >> "$dir_result"'result'

#	if [ -f "$dir_result"'result' ]
#	then
#
#		if [ $(cat "$dir_result"'result' | grep -c -e "$OTID") -eq '0' ]
#		then
#
##			echo "${2:0:14}" 'out in file'
#			echo ${2:0:14} $S_TIME_OF $OTID $S_TIME >> "$dir_result"'result'
#
#		fi
#
#	else
#
##		echo "${2:0:14}" 'out in file'
#		echo ${2:0:14} $S_TIME_OF $OTID $S_TIME >> "$dir_result"'result'
#
#	fi

done

rm "$dir_unlzma_lock"$2 &>> /dev/null
rm "$dir_unlzma"${2:0:14} &>> /dev/null

#kill -s 40 $1
