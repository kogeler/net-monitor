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

	temp=$(tshark -V -Y "( gsm_a.bssmap ) && ( gsm_a.bssmap.msgtype == 0x03 ) && ( gsm_a.rr.RRcause == 10 )" -r "$dir_unlzma"${2:0:14} 2>/dev/null)
	c_f_s=$(echo "$temp" | grep -c -e "RR cause value: Frequency not implemented (10)")

	if [ $c_f_s -gt '0' ]
	then

		f_s=$(echo "$temp" | grep -n -e "RR cause value: Frequency not implemented (10)")

	fi

fi

if [ $4 -eq '2' ]
then

	temp=$(tshark -V -Y "( gsm_a.bssmap ) && ( gsm_a.bssmap.msgtype == 0x03 ) && ( gsm_a.rr.RRcause == 111 )" -r "$dir_unlzma"${2:0:14} 2>/dev/null)
	c_f_s=$(echo "$temp" | grep -c -e "RR cause value: Protocol error unspecified (111)")

	if [ $c_f_s -gt '0' ]
	then

		f_s=$(echo "$temp" | grep -n -e "RR cause value: Protocol error unspecified (111)")

	fi

fi


if [ $4 -eq '3' ]
then

	temp=$(tshark -V -Y "( gsm_a.bssmap ) && ( gsm_a.bssmap.msgtype == 0x03 ) && ( gsm_a.rr.RRcause == 3 )" -r "$dir_unlzma"${2:0:14} 2>/dev/null)
	c_f_s=$(echo "$temp" | grep -c -e "RR cause value: Abnormal release, timer expired (3)")

	if [ $c_f_s -gt '0' ]
	then

		f_s=$(echo "$temp" | grep -n -e "RR cause value: Abnormal release, timer expired (3)")

	fi

fi

while [ $c_index -lt $c_f_s ]
do

	let c_index++

#	echo "${2:0:14}" 'S: ' $(echo "$f_s" | sed -n $c_index'p')

	n_s=$(echo "$f_s" | sed -n $c_index'p' | awk '{print $1}')
	n_s=${n_s%":"}

#	echo "${2:0:14}" 'n_s: ' $n_s

	while [ $n_s -gt '1' ]
	do

		let n_s--
		s=$(echo "$temp" | sed -n $n_s'p')

		if [ $s_index -eq '1' ]
		then

			if [ $(echo "$s" | grep -c -e '    Destination Local Reference: ') -gt '0' ]
			then

				DLR=$(echo "$s" | awk '{print $4}')
				let s_index++
				continue

			fi
		fi

		if [ $s_index -eq '2' ]
		then

			if [ $(echo "$s" | grep -c -e 'Frame Number:') -gt '0' ]
			then

				frame_num=$(echo "$s" | awk '{print $3}')
				let s_index++
				continue

			fi
		fi

		if [ $(echo "$s" | grep -c -e '    Arrival Time: ') -gt '0' ]
		then

			S_TIME=$(echo "$s" | awk '{print $6}')
			s_index='1'
			break

		fi

	done

if [ -f "$dir_result"'result' ]
then

	if [ $(cat "$dir_result"'result' | grep -c -e "$DLR") -eq '0' ]
	then

#		echo "${2:0:14}" 'out in file'

		echo ${2:0:14} $frame_num $DLR $S_TIME >> "$dir_result"'result'

	fi

else

#	echo "${2:0:14}" 'out in file'
	echo ${2:0:14} $frame_num $DLR $S_TIME >> "$dir_result"'result'
fi

done

rm "$dir_unlzma_lock"$2 &>> /dev/null
rm "$dir_unlzma"${2:0:14} &>> /dev/null
echo ${2:0:14} >> "$dir_main_temp"'prog1'

#kill -s 40 $1
