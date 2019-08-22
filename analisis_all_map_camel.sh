#!/bin/bash

dir_lzma='/media/data/wireshark/'
dir_lzma_mobile="$dir_lzma"'lzma-mobile/'

dir_ram='/media/ram1/wireshark/'
dir_unlzma="$dir_ram"'unlzma/'
dir_unlzma_lock="$dir_ram"'unlzma-lock/'
dir_result="$dir_ram"'result/'
dir_main_temp="$dir_ram"'main-temp/'

touch "$dir_unlzma_lock"$2 &>> /dev/null

7z x "$dir_lzma_mobile"$2 -o"$dir_unlzma" &>> /dev/null

n_s='0'
OTID='0'
DTID='0'
c_f_s='0'
c_index='0'
s_index='0'
frame_num='0'
S_TIME='0'

if [ $3 -eq '2' ] && [ $4 -eq '1' ]
then

        temp=$(tshark -V -t ad -Y "( gsm_old.opCode == 0 ) && ( e212.imsi contains $5 )" -r "$dir_unlzma"${2:0:14} 2>/dev/null)
        c_f_s=$(echo "$temp" | grep -c -e "IMSI:.*$5")

        if [ $c_f_s -gt '0' ]
        then

                f_s=$(echo "$temp" | grep -n -e "IMSI:.*$5")

        fi

fi

if [ $3 -eq '2' ] && [ $4 -eq '2' ]
then

        temp=$(tshark -V -t ad -Y "( tcap.begin_element ) && ( gsm_old.opCode == 0 ) && ( e164.msisdn contains $5 )" -r "$dir_unlzma"${2:0:14} 2>/dev/null)
        c_f_s=$(echo "$temp" | grep -c -e "E.164 number (MSISDN):.*$5")

        if [ $c_f_s -gt '0' ]
        then

                f_s=$(echo "$temp" | grep -n -e "E.164 number (MSISDN):.*$5")

        fi

fi

if [ $3 -eq '3' ] && [ $4 -eq '1' ]
then

	temp=$(tshark -V -t ad -Y "( tcap.begin_element ) && ( camel.local == 0 ) && ( e164.calling_party_number.digits contains $5 )" -r "$dir_unlzma"${2:0:14} 2>/dev/null)
	c_f_s=$(echo "$temp" | grep -c -e "E.164 Calling party number digits:.*$5")

	if [ $c_f_s -gt '0' ]
	then

		f_s=$(echo "$temp" | grep -n -e "E.164 Calling party number digits:.*$5")

	fi

fi

if [ $3 -eq '3' ] && [ $4 -eq '2' ]
then

	temp=$(tshark -V -t ad -Y "( tcap.begin_element ) && ( camel.local == 0 ) && ( gsm_a.dtap.cld_party_bcd_num contains $5 )" -r "$dir_unlzma"${2:0:14} 2>/dev/null)
	c_f_s=$(echo "$temp" | grep -c -e "Called Party BCD Number:.*$5")

	if [ $c_f_s -gt '0' ]
	then

#		echo "$temp"
		f_s=$(echo "$temp" | grep -n -e "Called Party BCD Number:.*$5")
#		echo "${2:0:14}" "$f_s"
#		echo "$temp" | sed -n $n_s'p'

	fi

fi

if [ $3 -eq '3' ] && [ $4 -eq '3' ]
then

	temp=$(tshark -V -t ad -Y "( tcap.begin_element ) && ( camel.local == 0 ) && ( e212.imsi contains $5 )" -r "$dir_unlzma"${2:0:14} 2>/dev/null)
	c_f_s=$(echo "$temp" | grep -c -e "IMSI:.*$5")

	if [ $c_f_s -gt '0' ]
	then

#		echo "$temp"
		f_s=$(echo "$temp" | grep -n -e "IMSI:.*$5")
#		echo "${2:0:14}" "$f_s"
#		echo "$temp" | sed -n $n_s'p'

	fi

fi

while [ $c_index -lt $c_f_s ]
do

	let c_index++
#	echo "${2:0:14}" 'S: ' $(echo "$f_s" | sed -n $c_index'p')
	n_s=$(echo "$f_s" | sed -n $c_index'p' | awk '{print $1}')
	n_s=${n_s%":"}
#	echo "${2:0:14}" 'n_s: ' $n_s

	OTID='0'
	DTID='0'
	s_index='1'

	while [ $n_s -gt '1' ]
	do

		let n_s--
		s=$(echo "$temp" | sed -n $n_s'p')


                if [ $s_index -eq '2' ] && [ $(echo "$s" | grep -c -e 'Transaction Capabilities Application Part') -gt '0' ]
                then

			if [ OTID == '0' ] && [ DTID == '0' ]
			then

				continue 2

			else

				let s_index++
				continue

			fi

                fi


		if [ $3 -eq '2' ] && [ $s_index -eq '1' ] && [ $(echo "$s" | grep -c -e 'opCode: localValue (0)') -gt '0' ]
                then

                        let s_index++
                        continue

                fi

		if [ $3 -eq '3' ] && [ $s_index -eq '1' ] && [ $(echo "$s" | grep -c -e 'local: initialDP (0)') -gt '0' ]
                then

                        let s_index++
                        continue

                fi

		if [ $s_index -eq '2' ] && [ $(echo "$s" | grep -c -e 'dtid: ') -gt '0' ]
		then

			DTID=$(echo "$s" | awk '{print $2}')
			continue

		fi


		if [ $s_index -eq '2' ] && [ $(echo "$s" | grep -c -e 'otid: ') -gt '0' ]
		then

			OTID=$(echo "$s" | awk '{print $2}')
			continue

		fi


		if [ $s_index -eq '3' ] && [ $(echo "$s" | grep -c -e 'Frame Number: ') -gt '0' ]
		then

			frame_num=$(echo "$s" | awk '{print $3}')
			let s_index++
			continue

		fi

		if [ $s_index -eq '4' ] && [ $(echo "$s" | grep -c -e 'Arrival Time: ') -gt '0' ]
		then

			S_TIME=$(echo "$s" | awk '{print $6}')
			break

		fi

	done

	if [ -f "$dir_result"'result' ]
	then

		if [ $(cat "$dir_result"'result' | grep -c -e "${2:0:14} $OTID $DTID") -eq '0' ] || [ ! -f "$dir_result"'result' ]
		then

#			echo "${2:0:14}" 'out in file'
			echo ${2:0:14} $OTID $DTID $frame_num $S_TIME >> "$dir_result"'result'

		fi

	else

		echo ${2:0:14} $OTID $DTID $frame_num $S_TIME >> "$dir_result"'result'

	fi

done

rm "$dir_unlzma_lock"$2 &>> /dev/null
rm "$dir_unlzma"${2:0:14} &>> /dev/null
echo ${2:0:14} >> "$dir_main_temp"'prog1'

#kill -s 40 $1
