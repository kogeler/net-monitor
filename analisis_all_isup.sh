#!/bin/bash

dir_ram='/media/ram1/wireshark/'
dir_unlzma="$dir_ram"'unlzma/'
dir_unlzma_lock="$dir_ram"'unlzma-lock/'
dir_result="$dir_ram"'result/'
dir_main_temp="$dir_ram"'main-temp/'

f_name=${2##'/'*'/'}
f_name=${f_name%'.7z'}

echo $$ > "$dir_unlzma_lock$f_name"

7z x "$2" -o"$dir_unlzma" &>> /dev/null

n_s='0'
TIME_P='0'
CIC='0'
OPC='0'
DPC='0'
c_f_s='0'
c_index='0'
s_index='0'
frame_num='0'

if [ $3 -eq '1' ] && [ $4 -eq '1' ]
then

	temp=$(tshark -V -Y "( isup.message_type == 1 ) && ( e164.calling_party_number.digits contains $5 )" -r "$dir_unlzma$f_name" 2>/dev/null)
	c_f_s=$(echo "$temp" | grep -c -e "E.164 Calling party number digits:.*$5")

	if [ $c_f_s -gt '0' ]
	then

		f_s=$(echo "$temp" | grep -n -e "E.164 Calling party number digits:.*$5")

	fi

fi

if [ $3 -eq '1' ] && [ $4 -eq '2' ]
then

	temp=$(tshark -V -t ad -Y "( isup.message_type == 1 ) && ( e164.called_party_number.digits contains $5 )" -r "$dir_unlzma$f_name" 2>/dev/null)
	c_f_s=$(echo "$temp" | grep -c -e "E.164 Called party number digits:.*$5")

	if [ $c_f_s -gt '0' ]
	then

#		echo "$temp"
		f_s=$(echo "$temp" | grep -n -e "E.164 Called party number digits:.*$5")
#		echo "${2:0:14}" "$f_s"
#		echo "$temp" | sed -n $n_s'p'

	fi

fi


while [ $c_index -lt $c_f_s ]
do

	let c_index++
	s_index='1'
#	echo "${2:0:14}" 'S: ' $(echo "$f_s" | sed -n $c_index'p')
	n_s=$(echo "$f_s" | sed -n $c_index'p' | awk '{print $1}')
	n_s=${n_s%":"}
#	echo "${2:0:14}" 'n_s: ' $n_s

	while [ $n_s -gt '1' ]
	do

		let n_s--
		s=$(echo "$temp" | sed -n $n_s'p')


		if [ $s_index -le '5' ] && [ $(echo "$s" | grep -c -e 'MTP 3 User Adaptation Layer') -gt '0' ]
		then

			continue 2

		fi

		if [ $s_index -eq '1' ] && [ $(echo "$s" | grep -c -e 'Message Type: Initial address (1)') -gt '0' ]
		then

			let s_index++
			continue

		fi

		if [ $s_index -eq '2' ] && [ $(echo "$s" | grep -c -e 'CIC: ') -gt '0' ]
		then

			CIC=$(echo "$s" | awk '{print $2}')
			let s_index++
			continue

		fi

		if [ $s_index -eq '3' ] && [ $(echo "$s" | grep -c -e 'ISDN User Part') -gt '0' ]
		then

			let s_index++
			continue

		fi


		if [ $s_index -eq '4' ] && [ $(echo "$s" | grep -c -e '\[DPC: ') -gt '0' ]
		then

			DPC=$(echo "$s" | awk '{print $2}')
			DPC=${DPC%']'}
			let s_index++
			continue

		fi

		if [ $s_index -eq '5' ] && [ $(echo "$s" | grep -c -e '\[OPC: ') -gt '0' ]
		then

			OPC=$(echo "$s" | awk '{print $2}')
			OPC=${OPC%']'}
			let s_index++
			continue

		fi

		if [ $s_index -eq '6' ] && [ $(echo "$s" | grep -c -e 'Frame Number: ') -gt '0' ]
		then

			frame_num=$(echo "$s" | awk '{print $3}')
			let s_index++
			continue

		fi

		if [ $s_index -eq '7' ] && [ $(echo "$s" | grep -c -e 'Arrival Time: ') -gt '0' ]
		then

			S_TIME=$(echo "$s" | awk '{print $6}')
			break

		fi

	done

#	echo "${2:0:14}" 'out in file'
	echo "$2" "$frame_num" "$CIC" "$OPC" "$DPC" "$S_TIME" >> "$dir_result"'result'

done

rm "$dir_unlzma_lock$f_name" &>> /dev/null
rm "$dir_unlzma$f_name" &>> /dev/null
echo "$f_name" >> "$dir_main_temp"'prog1'

#kill -s 40 $1
