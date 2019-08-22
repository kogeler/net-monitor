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

max_next_f='10'

DLR1="$4"
SLR2=$DLR1
DLR2='0'

frame_num="$3"

f=$(ls -1A "$dir_lzma_mobile_radio")
end_num_s_f=$(echo "$f" | wc -l)
num_s_f_orig=$(echo "$f" | grep -n -e "$2" | awk '{print $1}')
num_s_f_orig=${num_s_f_orig/':'/' '}
num_s_f_orig=$(echo "$num_s_f_orig" | awk '{print $1}')
num_s_f=$num_s_f_orig

#end_num_s_f=$(echo "$f" | wc -l)
#echo $end_num_s_f

c_ss='0'
n_ss='0'
n_s='0'
n_s_1='0'
n_s_2='0'
c_index='0'

for a in 1 2
do

	if [ $num_s_f -eq '0' ]
	then

		echo $5 'End file list!'
		break

	fi

	s_f=$(echo "$f" | sed -n $num_s_f'p')
	f_name=${s_f:0:14}

#	echo "$s_f"

	7z x "$dir_lzma_mobile_radio"$s_f -o"$dir_result_temp" &>> /dev/null

	if [ "$a" == '1' ]
	then

#		echo "seach: $num_s_f time: $S_TIME_OF"

		ws_out=$(tshark -V -t ad -Y "sccp.message_type == 0x02 && sccp.slr == $SLR2 && frame.number < $frame_num" \
		-r "$dir_result_temp"$f_name 2>/dev/null)

#		echo "$ws_out"

	else

#		echo "seach: $num_s_f time: $S_TIME_OF"

		ws_out=$(tshark -V -t ad -Y "sccp.message_type == 0x02 && sccp.slr == $SLR2" \
		-r "$dir_result_temp"$f_name 2>/dev/null)

#		echo "$ws_out"

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

#				echo "$SLR2 Find: $DLR2"

				break 2

			fi

			let c_index--

		done

	fi

	if [ "$a" == '2' ]
	then

	rm "$dir_result_temp$f_name"

	fi


	let num_s_f--

done

if [ "$DLR2" == '0' ] 
then

	num_s_f=$num_s_f_orig

	echo "$SLR2 NO Find"

fi

c_ss='0'
n_ss='0'
n_s='0'
c_index='0'

while [ $max_next_f -ne '0' ]
do

	if [ $num_s_f -gt $end_num_s_f ]
	then

		echo $5 'End file list!'
		break

	fi

	s_f=$(echo "$f" | sed -n $num_s_f'p')
	f_name=${s_f:0:14}

	#echo "$s_f"

	if [ ! -f "$dir_result_temp$f_name" ]
	then

		7z x "$dir_lzma_mobile_radio"$s_f -o"$dir_result_temp" &>> /dev/null

	fi

	if [ "$DLR2" == '0' ]
	then

		tshark -Y "sccp.lr == $SLR2" \
		-r "$dir_result_temp"$f_name -F pcapng -w "$dir_result_temp"'_'$f_name 2>/dev/null

	else

		tshark -Y "( sccp.lr == $SLR2 || sccp.lr == $DLR2 )" \
		-r "$dir_result_temp"$f_name -F pcapng -w "$dir_result_temp"'_'$f_name 2>/dev/null

	fi

	rm "$dir_result_temp"$f_name
	mv "$dir_result_temp"'_'$f_name "$dir_result_temp"$f_name

	if [ "$DLR2" == '0' ]
	then

		ws_out=$(tshark -V -t ad -Y "( sccp.lr == $SLR2 && ( sccp.message_type == 0x04 || sccp.message_type == 0x05 ) )" \
		-r "$dir_result_temp"$f_name 2>/dev/null)

	else

		ws_out=$(tshark -V -t ad -Y "( sccp.lr == $SLR2 && sccp.lr == $DLR2 && ( sccp.message_type == 0x04 || sccp.message_type == 0x05 ) )" \
		-r "$dir_result_temp"$f_name 2>/dev/null)

	fi

	if [ "$ws_out" != "" ]
	then

#		echo "$ws_out"

		c_ss=$(echo "$ws_out" | grep -c -E "Message Type: Released \(0x04\)|Message Type: Release Complete \(0x05\)") 
		n_ss=$(echo "$ws_out" | grep -n -E "Message Type: Released \(0x04\)|Message Type: Release Complete \(0x05\)")
		c_index=$c_ss

		while [ $c_index -ge '1' ]
		do

			n_s=$(echo "$n_ss" | sed -n $c_index'p' | awk '{print $1}')
			n_s=${n_s/':'/''}
			let "n_s_1 = n_s + 1"
			let "n_s_2 = n_s + 2"

			if [ $(echo "$ws_out" | sed -n $n_s_1'p' | grep -c -E "$SLR2|$DLR2") -gt '0' ] || \
			[ $(echo "$ws_out" | sed -n $n_s_2'p' | grep -c -E "$SLR2|$DLR2") -gt '0' ]
			then

				break 2

			fi

			let c_index--

		done

	fi

	let num_s_f++
	let max_next_f--

done

echo "$SLR2 $DLR2 $max_next_f"

f=$(ls -1A "$dir_result_temp")

if [ $(echo "$f" | wc -l) -eq '0' ]
then
rm -rf "$dir_result_temp"
fi

if [ $(echo "$f" | wc -l) -eq '1' ]
then
mv "$dir_result_temp"$f "$dir_result${2:0:8} $5"
rm -rf "$dir_result_temp"
fi

if [ $(echo "$f" | wc -l) -gt '1' ]
then
	for file in $f
	do
	all_file="$all_file $dir_result_temp$file"
	done
mergecap -F pcapng -w "$dir_result${2:0:8} $5" $all_file
rm -rf "$dir_result_temp"
fi

echo $f_name >> "$dir_main_temp"'prog2'
