#!/bin/bash

dir_lzma='/media/data/wireshark/'
dir_lzma_mobile_radio="$dir_lzma"'lzma-mobile-radio/'

dir_ram='/media/ram1/wireshark/'
dir_unlzma="$dir_ram"'unlzma/'
dir_unlzma_lock="$dir_ram"'unlzma-lock/'
dir_result="$dir_ram"'result/'
dir_main_temp="$dir_ram"'main-temp/'

touch "$dir_unlzma_lock"$2 &>> /dev/null

7z x "$dir_lzma_mobile_radio"$2 -o"$dir_unlzma" &>> /dev/null

n_s='0'
TIME_P='0'
DLR='0'
c_f_s='0'
c_index='0'
s_index='1'

if [ $4 -eq '1' ]
then

	temp=$(tshark -V -Y "( gsm_a.bssmap ) && ( gsm_a.rr.RRcause )" -r "$dir_unlzma"${2:0:14} 2>/dev/null)
	c_f_s=$(echo "$temp" | grep -c -e "RR cause value: ")

	if [ $c_f_s -gt '0' ]
	then

		f_s=$(echo "$temp" | grep -n -e "RR cause value: ")

	fi

fi

while [ $c_index -lt $c_f_s ]
do

	let c_index++

#	echo "${2:0:14}" 'S: ' $(echo "$f_s" | sed -n $c_index'p')

	n_s=$(echo "$f_s" | sed -n $c_index'p' | awk '{print $1}')
	n_s=${n_s%":"}

#	echo "${2:0:14}" 'n_s: ' $n_s

	err_msg=$(echo "$temp" | sed -n $n_s'p')

	while [ $n_s -gt '1' ]
	do

		let n_s--
		s=$(echo "$temp" | sed -n $n_s'p')

		if [ $(echo "$s" | grep -c -e 'Message Type') -gt '0' ]
		then

			type_msg=$s
			break

		fi

	done

	echo  $type_msg $err_msg ${2:0:14} >> "$dir_result"'result'

done

rm "$dir_unlzma_lock"$2 &>> /dev/null
rm "$dir_unlzma"${2:0:14} &>> /dev/null
echo ${2:0:14} >> "$dir_main_temp"'prog1'

#kill -s 40 $1
