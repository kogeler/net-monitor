#!/bin/bash

dir_scripts='/opt/net-monitor/'

dir_lzma='/media/data/wireshark/'
dir_lzma_mobile="$dir_lzma"'lzma-mobile/'
dir_lzma_mobile_radio="$dir_lzma"'lzma-mobile-radio/'
dir_lzma_pstn="$dir_lzma"'lzma-pstn/'
dir_lzma_curent=''

dir_ram='/media/ram1/wireshark/'
dir_unlzma="$dir_ram"'unlzma/'
dir_unlzma_lock="$dir_ram"'unlzma-lock/'
dir_result="$dir_ram"'result/'
dir_result_temp="$dir_ram"'result-temp/'
dir_main_temp="$dir_ram"'main-temp/'

num_of_threads='14'

n_s='1'
end_n_s='0'

find_file=''
prog_index='0'
max_prog_index='0'
p_prog='0'

#int_40 ()
#{

#	let num_thread--

#}

#trap int_40 40

find "$dir_unlzma" -maxdepth 1 -type f -delete &>> /dev/null
find "$dir_unlzma_lock" -maxdepth 1 -type f -delete &>> /dev/null
find "$dir_result" -maxdepth 1 -type f -delete &>> /dev/null
find "$dir_result_temp" -maxdepth 1 -type f -delete &>> /dev/null
find "$dir_main_temp" -maxdepth 1 -type f -delete &>> /dev/null

echo "Chooses a protocol:"
echo "1 - ISUP, 2 - MAP, 3 - CAMEL,"
echo "4 - BSSAP error, 5 - BSSAP all error,"
echo "6 - BSSAP and RANAP,"
echo "7 - ISUP(PSTN)."
read -e -p "Protocol: " proto

if [ $proto -eq 1 ] || [ $proto -eq 7 ]
then

	echo "Chooses a filter:"
	echo "1 - A-number, 2 - B-number."
	read -e -p "Filter: " filter

fi

if [ $proto -eq 2 ]
then

	echo "Chooses a filter:"
	echo "1 - IMSI, 2 - MSISDN."
	read -e -p "Filter: " filter

fi

if [ $proto -eq 3 ]
then

	echo "Chooses a filter:"
	echo "1 - A-number, 2 - B-number, 3 - IMSI."
	read -e -p "Filter: " filter

fi

if [ $proto -eq 4 ]
then

	echo "Chooses a filter:"
	echo "1 - Assignment Failure: Frequency not implemented (10),"
	echo "2 - Assignment Failure: Protocol error unspecified (111),"
	echo "3 - RR cause value: Abnormal release, timer expired (3)."
	read -e -p "Filter: " filter

fi

if [ $proto -eq 5 ]
then

	echo "Chooses a filter:"
	echo "1 - All bssap error."
	read -e -p "Filter: " filter

fi

if [ $proto -eq 6 ]
then

	echo "Chooses a filter:"
	echo "1 - IMEISV."
	read -e -p "Filter: " filter

fi

read -e -p "The filter value: "  param_1

read -e -i $(date '+%Y') -p "Start_ГОД   : " start_YYYY
start_YYYY=${start_YYYY#0}
read -e -i $(date '+%m') -p "Start_МЕСЯЦ : " start_MM
start_MM=${start_MM#0}
read -e -i $(date '+%d') -p "Start_ДЕНЬ  : " start_DD
start_DD=${start_DD#0}
read -e -i $(date '+%H') -p "Start_ЧАС   : " start_hh
start_hh=${start_hh#0}
read -e -i $(date '+%M') -p "Start_МИНУТА: " start_mm
start_mm=${start_mm#0}
echo
read -e -i $(date '+%Y') -p "Stop_ГОД    : " stop_YYYY
stop_YYYY=${stop_YYYY#0}
read -e -i $(date '+%m') -p "Stop_МЕСЯЦ  : " stop_MM
stop_MM=${stop_MM#0}
read -e -i $(date '+%d') -p "Stop_ДЕНЬ   : " stop_DD
stop_DD=${stop_DD#0}
read -e -i $(date '+%H') -p "Stop_ЧАС    : " stop_hh
stop_hh=${stop_hh#0}
read -e -i $(date '+%M') -p "Stop_МИНУТА : " stop_mm
stop_mm=${stop_mm#0}

echo
echo 'Начало общего анализа ...'

if [ $proto -eq 1 ]
then

	dir_lzma_curent="$dir_lzma_mobile"

fi

if [ $proto -eq 2 ]
then

	dir_lzma_curent="$dir_lzma_mobile"

fi

if [ $proto -eq 3 ]
then

	dir_lzma_curent="$dir_lzma_mobile"

fi

if [ $proto -eq 4 ]
then

	dir_lzma_curent="$dir_lzma_mobile_radio"

fi

if [ $proto -eq 5 ]
then

	dir_lzma_curent="$dir_lzma_mobile_radio"

fi

if [ $proto -eq 6 ]
then

        dir_lzma_curent="$dir_lzma_mobile_radio"

fi

if [ $proto -eq 7 ]
then

        dir_lzma_curent="$dir_lzma_pstn"

fi

f=$(ls -1A "$dir_lzma_curent")

for file in $f
do

	f_YYYY=${file:0:4}
	f_YYYY=${f_YYYY#0}
	f_MM=${file:4:2}
	f_MM=${f_MM#0}
	f_DD=${file:6:2}
	f_DD=${f_DD#0}

	f_hh=${file:8:2}
	f_hh=${f_hh#0}
	f_mm=${file:10:2}
	f_mm=${f_mm#0}

	if [ $f_YYYY -gt $stop_YYYY ] || \
	[ $f_YYYY -eq $stop_YYYY -a $f_MM -gt $stop_MM   ] || \
	[ $f_YYYY -eq $stop_YYYY -a $f_MM -eq $stop_MM -a $f_DD -gt $stop_DD ] || \
	[ $f_YYYY -eq $stop_YYYY -a $f_MM -eq $stop_MM -a $f_DD -eq $stop_DD -a $f_hh -gt $stop_hh ] || \
	[ $f_YYYY -eq $stop_YYYY -a $f_MM -eq $stop_MM -a $f_DD -eq $stop_DD -a $f_hh -eq $stop_hh -a $f_mm -gt $stop_mm ]
	then

		break

	fi

	if [ $f_YYYY -gt $start_YYYY ] || \
	[ $f_YYYY -eq $start_YYYY -a $f_MM -gt $start_MM   ] || \
	[ $f_YYYY -eq $start_YYYY -a $f_MM -eq $start_MM -a $f_DD -gt $start_DD ] || \
	[ $f_YYYY -eq $start_YYYY -a $f_MM -eq $start_MM -a $f_DD -eq $start_DD -a $f_hh -gt $start_hh ] || \
	[ $f_YYYY -eq $start_YYYY -a $f_MM -eq $start_MM -a $f_DD -eq $start_DD -a $f_hh -eq $start_hh -a $f_mm -ge $start_mm ]
	then

		find_file=$(echo -e "$find_file\n$file")

	fi

done

find_file=$(echo "$find_file" | sed -e '1d')
#echo "$find_file"
#read -e -p 'Для продолжения  нажмите любую клавишу...'  abc

max_prog_index=$(echo "$find_file" | wc -l)
p_prog=$(vramsteg --now)
vramsteg --start $p_prog --percentage --width 30 --min 0 --max $max_prog_index --current 0

for file in $find_file
do

	if [ -f "$dir_main_temp"'prog1' ]
	then

		prog_index=$(cat "$dir_main_temp"'prog1' | wc -l)
		vramsteg --start $p_prog --percentage --width 30 --min 0 --max $max_prog_index --current $prog_index

	fi

	while [ $(ls -1A "$dir_unlzma_lock" | wc -l) -ge $num_of_threads ]
	do

		sleep 1

	done

	if [ $proto -eq 1 ]
	then

		"$dir_scripts"'analisis_all_isup.sh' $$ "$dir_lzma_curent$file" $proto $filter $param_1 &

	fi

	if [ $proto -eq 2 ] || [ $proto -eq 3 ]
	then

		"$dir_scripts"'analisis_all_map_camel.sh' $$ $file $proto $filter $param_1 &

	fi

	if [ $proto -eq 4 ]
	then

		"$dir_scripts"'analisis_all_bssap_err.sh' $$ $file $proto $filter $param_1 &

	fi

	if [ $proto -eq 5 ]
	then

		"$dir_scripts"'analisis_all_bssap_find_all_err.sh' $$ $file $proto $filter $param_1 &

	fi

	if [ $proto -eq 6 ]
	then

		"$dir_scripts"'analisis_all_bssap_ranap.sh' $$ $file $proto $filter $param_1 &

        fi

done

while [ $(ls -1A "$dir_unlzma_lock" | wc -l) -gt '0' ]
do

	if [ -f "$dir_main_temp"'prog1' ]
	then

		prog_index=$(cat "$dir_main_temp"'prog1' | wc -l)
		vramsteg --start $p_prog --percentage --width 30 --min 0 --max $max_prog_index --current $prog_index

	fi

sleep 1

done

vramsteg --remove --width 30

echo 'Завершение общего анализа!'
echo

#read -e -p 'Для продолжения  нажмите любую клавишу...'  abc

if [ -f "$dir_result"'result' ]
then

	echo 'Начало анализа обменов...'
	f=$(cat "$dir_result"'result')
	end_n_s=$(echo "$f" | wc -l)

	max_prog_index=$(echo "$f" | wc -l)
#	echo "$end_n_s"
	p_prog=$(vramsteg --now)
	vramsteg --start $p_prog --percentage --width 30 --min 0 --max $max_prog_index --current 0

	while [ $n_s -le $end_n_s ]
	do

		if [ -f "$dir_main_temp"'prog2' ]
		then

			prog_index=$(cat "$dir_main_temp"'prog2' | wc -l)
			vramsteg --start $p_prog --percentage --width 30 --min 0 --max $max_prog_index --current $prog_index

		fi

		while [ $(ls -1A "$dir_result_temp" | wc -l) -ge $num_of_threads ]
		do

			sleep 1

		done

		s=$(echo "$f" | sed -n $n_s'p')

		if [ $proto -eq 1 ]
		then

			"$dir_scripts"'analisis_one_isup.sh' $$ $s &

		fi

		if [ $proto -eq 2 ] || [ $proto -eq 3 ]
		then

			"$dir_scripts"'analisis_one_map_camel.sh' $$ $s &

		fi

		if [ $proto -eq 4 ]
		then

			"$dir_scripts"'analisis_one_bssap_err.sh' $$ $s &

		fi

		if [ $proto -eq 5 ]
		then

			break

		fi

		if [ $proto -eq 6 ]
		then

			"$dir_scripts"'analisis_one_bssap_ranap.sh' $$ $s &
#			break

		fi

		let n_s++
		let prog_index++

	done

	sleep 1

	while [ $(ls -1A "$dir_result_temp" | wc -l) -gt '0' ]
	do

		if [ -f "$dir_main_temp"'prog2' ]
		then

			prog_index=$(cat "$dir_main_temp"'prog2' | wc -l)
			vramsteg --start $p_prog --percentage --width 30 --min 0 --max $max_prog_index --current $prog_index

		fi

		sleep 1

	done

	vramsteg --remove --width 30

	echo 'Завершение анализа обменов!'
	echo

else

	echo 'Обменов не обнаружено!'
	echo

fi

read -e -p 'Для выхода нажмите любую клавишу...'  abc
