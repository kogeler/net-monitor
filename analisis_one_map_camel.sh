#!/bin/bash

dir_lzma='/media/data/wireshark/'
dir_lzma_mobile="$dir_lzma"'lzma-mobile/'

dir_ram='/media/ram1/wireshark/'
dir_result="$dir_ram"'result/'
dir_main_temp="$dir_ram"'main-temp/'

#ran=$RANDOM
ran=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20 | xargs)
dir_result_temp="$dir_ram"'result-temp/'$ran'/'
mkdir "$dir_result_temp"

OTID="$3"
DTID="$4"
TID1='0'
TID1_HEX='0'
TID2='0'
TID2_HEX='0'

if [ OTID != '0' ] && [ DTID == '0' ]
then

	TID1=$OTID
	TID1_HEX=$(echo $TID1 | sed 's/\(..\)/\1:/g;s/:$//')

fi

if [ OTID == '0' ] && [ DTID != '0' ]
then

	TID1=$DTID
	TID1_HEX=$(echo $TID1 | sed 's/\(..\)/\1:/g;s/:$//')

fi

if [ OTID != '0' ] && [ DTID != '0' ]
then

        TID1=$OTID
        TID1_HEX=$(echo $TID1 | sed 's/\(..\)/\1:/g;s/:$//')
	TID2=$DTID
        TID2_HEX=$(echo $TID2 | sed 's/\(..\)/\1:/g;s/:$//')

fi

frame_num_1="$3"

f=$(ls -1A "$dir_lzma_mobile")
num_s_f=$(echo "$f" | grep -n -e "$2" | awk '{print $1}')
num_s_f=${num_s_f/':'/' '}
num_s_f=$(echo "$num_s_f" | awk '{print $1}')
end_num_s_f=$(echo "$f" | wc -l)
#echo $end_num_s_f

c_ss='0'
n_ss='0'
n_s='0'
c_index='0'

for a in 1 2 3 4 5
do

	if [ $num_s_f -gt $end_num_s_f ]
	then

		echo $5 'End file list!'
		break

	fi

	s_f=$(echo "$f" | sed -n $num_s_f'p')
	f_name=${s_f:0:14}
#	echo "$s_f"
	7z x "$dir_lzma_mobile"$s_f -o"$dir_result_temp" &>> /dev/null

	if [ "$TID2" == '0' ]
	then

#		echo "seach: $num_s_f"
		ws_out=$(tshark -V -t ad -Y "tcap.tid == $TID1_HEX" -r "$dir_result_temp"$f_name 2>/dev/null)
#		echo "$ws_out"

		if [ "$ws_out" != "" ]
		then

			c_ss=$(echo "$ws_out" | grep -c -e ": $TID1")
			n_ss=$(echo "$ws_out" | grep -n -e ": $TID1")

			while [ $c_index -lt $c_ss ]
			do

				let c_index++
				n_s=$(echo "$n_ss" | sed -n $c_index'p' | awk '{print $1}')
				n_s=${n_s/':'/' '}
				let "n_s += 2"

				if [ $(echo "$ws_out" | sed -n $n_s'p' |  grep -c -E "otid: |dtid: ") -gt '0' ]
				then

					TID2=$(echo "$ws_out" | sed -n $n_s'p' | awk '{print $2}')
					TID2_HEX=$(echo $TID2 | sed 's/\(..\)/\1:/g;s/:$//')
					echo "$TID1_HEX Find TID2:  $TID2_HEX"
					break

				fi

				let "n_s -= 4"

				if [ $(echo "$ws_out" | sed -n $n_s'p' |  grep -c -E "otid: |dtid: ") -gt '0' ]
				then

					TID2=$(echo "$ws_out" | sed -n $n_s'p' | awk '{print $2}')
					TID2_HEX=$(echo $TID2 | sed 's/\(..\)/\1:/g;s/:$//')
					echo "$TID1_HEX Find TID2:  $TID2_HEX"
					break

				fi

			done
		fi

	fi

	if [ "$TID2" == '0' ]
	then

		tshark -Y "tcap.tid == $TID1_HEX" \
		-r "$dir_result_temp"$f_name -F pcapng -w "$dir_result_temp"'_'$f_name 2>/dev/null

	else

		tshark -Y "tcap.tid == $TID1_HEX || tcap.tid == $TID2_HEX" \
		-r "$dir_result_temp"$f_name -F pcapng -w "$dir_result_temp"'_'$f_name 2>/dev/null

	fi

	rm "$dir_result_temp"$f_name
	mv "$dir_result_temp"'_'$f_name "$dir_result_temp"$f_name

	if [ "$TID2" == '0' ]
	then

		ws_out=$(tshark -V -t ad -Y "tcap.tid == $TID1_HEX && tcap.end_element" -r "$dir_result_temp"$f_name 2>/dev/null)

	else

		ws_out=$(tshark -V -t ad -Y "( tcap.tid == $TID1_HEX || tcap.tid == $TID2_HEX ) && tcap.end_element" -r "$dir_result_temp"$f_name 2>/dev/null)

	fi

	if [ "$ws_out" != "" ]
	then

#		echo "Find!"
		break

	fi

	let num_s_f++

done

f=$(ls -1A "$dir_result_temp")

if [ $(echo "$f" | wc -l) -eq '0' ]
then

	rm -rf "$dir_result_temp"

fi

if [ $(echo "$f" | wc -l) -eq '1' ]
then

	mv "$dir_result_temp"$f "$dir_result${2:0:8} $6"
	rm -rf "$dir_result_temp"

fi

if [ $(echo "$f" | wc -l) -gt '1' ]
then

	for file in $f
	do

		all_file="$all_file $dir_result_temp$file"

	done

	mergecap -F pcapng -w "$dir_result${2:0:8} $6" $all_file
	rm -rf "$dir_result_temp"

fi

echo $f_name >> "$dir_main_temp"'prog2'
