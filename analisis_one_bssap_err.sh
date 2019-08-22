#!/bin/bash

dir_lzma='/media/data/wireshark/'
dir_lzma_mobile_radio="$dir_lzma"'lzma-mobile-radio/'

dir_ram='/media/ram1/wireshark/'
dir_result="$dir_ram"'result/'
dir_main_temp="$dir_ram"'main-temp/'

#ran=$RANDOM
ran=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20 | xargs)
dir_result_temp="$dir_ram"'result-temp/'$ran'/'
mkdir "$dir_result_temp"

DLR1="$4"
SLR2=$DLR1
DLR2='0'
SLR3='0'

frame_num_1="$3"
frame_num_2='0'

f=$(ls -1A "$dir_lzma_mobile_radio")
num_s_f=$(echo "$f" | grep -n -e "$2" | awk '{print $1}')
num_s_f=${num_s_f/':'/' '}
num_s_f=$(echo "$num_s_f" | awk '{print $1}')
end_num_s_f=$(echo "$f" | wc -l)

#echo $end_num_s_f

c_ss='0'
n_ss='0'
n_s='0'
c_index='0'
s_index='1'

LAC='0'
CI='0'
IMEISV='0'

for a in 1 2
do

	if [ $LAC != '0' ] && [ $CI != '0' ]
	then

		break

	fi

	s_f=$(echo "$f" | sed -n $num_s_f'p')
	f_name=${s_f:0:14}

#	echo "$s_f"

	7z x "$dir_lzma_mobile_radio"$s_f -o"$dir_result_temp" &>> /dev/null

	if [ "$IMEISV" == '0' ] 
	then

		if [ "$a" == '1' ]
		then

#			echo "search: $DLR1 frame: $frame_num_1"

			ws_out=$(tshark -V -t ad -Y "sccp.dlr == $DLR1 && gsm_a.bssmap.msgtype == 0x55 && frame.number < $frame_num_1" -r "$dir_result_temp"$f_name 2>/dev/null)

#			echo "$ws_out"

		else

#			echo "search: $DLR1"

			ws_out=$(tshark -V -t ad -Y "sccp.dlr == $DLR1 && gsm_a.bssmap.msgtype == 0x55" -r "$dir_result_temp"$f_name 2>/dev/null)

#			echo "$ws_out"

		fi

		if [ "$ws_out" != "" ]
		then

			c_ws_out=$(echo "$ws_out" | wc -l)

#			echo "$c_ws_out"

			c_ss=$(echo "$ws_out" | grep -c -e "Destination Local Reference: $DLR1")
			n_ss=$(echo "$ws_out" | grep -n -e "Destination Local Reference: $DLR1")
			c_index=$c_ss

			while [ $c_index -ge '1' ]
			do

				n_s=$(echo "$n_ss" | sed -n $c_index'p' | awk '{print $1}')
				n_s=${n_s/':'/''}

				while [ $n_s -le $c_ws_out ]
				do

					let n_s++
					s=$(echo "$ws_out" | sed -n $n_s'p')

					if [ $(echo "$s" | grep -c -e 'Signalling Connection Control Part') -gt '0' ]
					then

						break

					fi

					if [ $(echo "$s" | grep -c -e 'Mobile Identity Type: IMEISV (3)') -gt '0' ]
					then

						let n_s++
						s=$(echo "$ws_out" | sed -n $n_s'p')
						IMEISV=$(echo "$s" | awk '{print $3}')
#						echo "find IMEISV: $IMEISV"
						break 2

					fi

				done

				let c_index--

			done

		fi

	fi

	if [ "$DLR2" == '0' ] && [ "$IMEISV" != '0' ]
	then

		if [ "$a" == '1' ]
		then

#			echo "seach: $num_s_f time: $S_TIME_OF"

			ws_out=$(tshark -V -t ad -Y "sccp.message_type == 0x02 && sccp.slr == $SLR2 && frame.number < $frame_num_1" -r "$dir_result_temp"$f_name 2>/dev/null)

#			echo "$ws_out"

		else

#			echo "seach: $num_s_f time: $S_TIME_OF"

			ws_out=$(tshark -V -t ad -Y "sccp.message_type == 0x02 && sccp.slr == $SLR2" -r "$dir_result_temp"$f_name 2>/dev/null)

#			echo "$ws_out"

		fi

		if [ "$ws_out" != "" ]
		then

			c_ss=$(echo "$ws_out" | grep -c -e "Source Local Reference: $SLR2")
			n_ss=$(echo "$ws_out" | grep -n -e "Source Local Reference: $SLR2")
			c_index=$c_ss

			while [ $c_index -ge '1' ]
			do

				n_s=$(echo "$n_ss" | sed -n $c_index'p' | awk '{print $1}')
				n_s=${n_s/':'/''}
				let "n_s -= 1"

				if [ $(echo "$ws_out" | sed -n $n_s'p' | grep -c -e 'Destination Local Reference:') -gt '0' ]
				then

					DLR2=$(echo "$ws_out" | sed -n $n_s'p' | awk '{print $4}')
					SLR3=$DLR2

					while [ $n_s -ge '1' ]
					do

						let n_s--
						s=$(echo "$ws_out" | sed -n $n_s'p')

						if [ $(echo "$s" | grep -c -e 'Frame Number: ') -gt '0' ]
						then

							frame_num_2=$(echo "$s" | awk '{print $3}')
							break

						fi
					done

#					echo "$SLR2 Find: $DLR2 $frame_num_2"
					break

				fi

				let c_index--

			done

		fi

	fi

	if [ "$DLR2" != '0' ] 
	then

		if [ "$a" == '1' ]
		then

#			echo "seach: $num_s_f time: $S_TIME_OF"

			ws_out=$(tshark -V -t ad -Y "sccp.message_type == 0x01 && sccp.slr == $SLR3 && gsm_a.bssmap.msgtype == 0x57 && frame.number < $frame_num_2" -r "$dir_result_temp"$f_name 2>/dev/null)

#			echo "$ws_out"

		else

#			echo "seach: $num_s_f time: $S_TIME_OF"

			ws_out=$(tshark -V -t ad -Y "sccp.message_type == 0x01 && sccp.slr == $SLR3 && gsm_a.bssmap.msgtype == 0x57" -r "$dir_result_temp"$f_name 2>/dev/null)

#			echo "$ws_out"

		fi

		if [ "$ws_out" != "" ]
		then

			c_ws_out=$(echo "$ws_out" | wc -l)

#			echo "$c_ws_out"

			c_ss=$(echo "$ws_out" | grep -c -e "Source Local Reference: $SLR3")
			n_ss=$(echo "$ws_out" | grep -n -e "Source Local Reference: $SLR3")
			c_index=$c_ss
			s_index='1'

			while [ $c_index -ge '1' ]
			do

				n_s=$(echo "$n_ss" | sed -n $c_index'p' | awk '{print $1}')
				n_s=${n_s/':'/''}

				while [ $n_s -le $c_ws_out ]
				do

					let n_s++
					s=$(echo "$ws_out" | sed -n $n_s'p')

					if [ $(echo "$s" | grep -c -e 'Signalling Connection Control Part') -gt '0' ]
					then

						break

					fi

					if [ $s_index -eq '1' ]
					then

						if [ $(echo "$s" | grep -c -e 'Cell LAC: ') -gt '0' ]
						then

							LAC=$(echo "$s" | awk '{print $4}')
							LAC=${LAC/'('/''}
							LAC=${LAC/')'/''}
							let s_index++
							continue

						fi

					fi

					if [ $s_index -eq '2' ]
					then

						if [ $(echo "$s" | grep -c -e 'Cell CI: ') -gt '0' ]
						then

							CI=$(echo "$s" | awk '{print $4}')
							CI=${CI/'('/''}
							CI=${CI/')'/''}
							break 2

						fi

					fi

				done

				let c_index--

			done

		fi

	fi

	rm "$dir_result_temp"$f_name

	let num_s_f--

done

if [ $LAC != '0' ] && [ $CI != '0' ]  
then

	echo "250-01-$LAC-$CI $IMEISV $5 $f_name $DLR1 $DLR2" >>  "$dir_result"'result2'

else

	echo "error: 250-01-$LAC-$CI $IMEISV $5 $f_name $DLR1 $DLR2" >>  "$dir_result"'result2'

fi


rm -rf "$dir_result_temp"

echo $f_name >> "$dir_main_temp"'prog2'
