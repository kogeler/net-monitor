#!/bin/bash

dir_scripts='/opt/net-monitor/'

dir_lzma='/media/data/wireshark/'
dir_lzma_mobile_radio="$dir_lzma"'lzma-mobile-radio/'

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

yesterday_date=$(date "+%Y.%m.%d" -d "yesterday")
today_date=$(date "+%Y.%m.%d")

if [ "$2" == '1' ]
then

	dir_stat_err='/media/data/wireshark/stat/bssap_err_1/'

fi

if [ "$2" == '2' ]
then

	dir_stat_err='/media/data/wireshark/stat/bssap_err_2/'

fi

if [ "$1" == '1' ]
then

	dir_stat="$dir_stat_err""$yesterday_date"'/'

fi

if [ "$1" == '2' ]
then

	dir_stat="$dir_stat_err""$today_date"'/'

fi

if [ ! -d "$dir_stat" ]
then

	mkdir "$dir_stat"

fi

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

if [ "$1" == '1' ]
then

	start_YYYY=$(date "+%Y" -d "yesterday")

	start_MM=$(date "+%m" -d "yesterday")

	start_DD=$(date "+%d" -d "yesterday")

	start_hh='00'

	start_mm='00'

	stop_YYYY=$(date "+%Y")

	stop_MM=$(date "+%m")

	stop_DD=$(date "+%d")

	stop_hh='00'

	stop_mm='00'

fi

if [ "$1" == '2' ]
then

	start_YYYY=$(date "+%Y")

	start_MM=$(date "+%m")

	start_DD=$(date "+%d")

	start_hh='00'

	start_mm='00'

	stop_YYYY=$(date "+%Y")

	stop_MM=$(date "+%m")

	stop_DD=$(date "+%d")

	stop_hh='06'

	stop_mm='00'

fi

f=$(ls -1A "$dir_lzma_mobile_radio")

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

for file in $find_file
do

	while [ $(ls -1A "$dir_unlzma_lock" | wc -l) -ge $num_of_threads ]
	do

		sleep 1

	done

	"$dir_scripts"'analisis_all_bssap_err.sh' $$ $file 4 $2 0 &

done

while [ $(ls -1A "$dir_unlzma_lock" | wc -l) -gt '0' ]
do

	sleep 1

done

if [ -f "$dir_result"'result' ]
then

	f=$(cat "$dir_result"'result')
	end_n_s=$(echo "$f" | wc -l)

	while [ $n_s -le $end_n_s ]
	do

		while [ $(ls -1A "$dir_result_temp" | wc -l) -ge $num_of_threads ]
		do

			sleep 1

		done

		s=$(echo "$f" | sed -n $n_s'p')
		"$dir_scripts"'analisis_one_bssap_err.sh' $$ $s &
		let n_s++

	done

	sleep 1

	while [ $(ls -1A "$dir_result_temp" | wc -l) -gt '0' ]
	do

		sleep 1

	done

fi

if [ -f "$dir_result"'result2' ]
then

	if [ "$1" == '1' ]
	then

		report='report'
		cp "$dir_result"'result2' "$dir_stat"'resuslt'
		comm_out=$(cat "$dir_stat"'resuslt')

	fi

	if [ "$1" == '2' ]
	then

		report='report_night'
		cp "$dir_result"'result2' "$dir_stat"'resuslt_night'
		comm_out=$(cat "$dir_stat"'resuslt_night')

	fi

	echo 'Отчет по БС:' >> "$dir_stat""$report"
	echo >> "$dir_stat""$report"
	echo "$comm_out" | awk '{print $1}' | sort | uniq -c | sort -bg >> "$dir_stat""$report"
	echo >> "$dir_stat""$report"
	echo 'Отчет по БС и IMEISV:' >> "$dir_stat""$report"
	echo >> "$dir_stat""$report"
	echo "$comm_out" | awk '{print $1" "$2}' | sort | uniq -c | sort -bg >> "$dir_stat""$report"
	echo >> "$dir_stat""$report"
	echo 'Почасовой отчет по БС и IMEISV:' >> "$dir_stat""$report"
	echo >> "$dir_stat""$report"

	s=''
	temp_buf=''

	comm_out=$(echo "$comm_out" | sort -k 3 )
	c_comm_out=$(echo "$comm_out" | wc -l)
	c_index='1'

	while [ $c_index -le $c_comm_out ]
	do

		s=$(echo "$comm_out" | sed -n $c_index'p' )
		s_3=$(echo "$s" | awk '{print $3}')
		temp_hour=${s_3:0:2}

		if [ $c_index -eq '1' ]
		then

			hour=$temp_hour

		fi

		if [ $temp_hour != $hour ]
		then

			echo "Час $hour:" >> "$dir_stat""$report"
			echo >> "$dir_stat""$report"
			echo "$temp_buf" | awk '{print $1}' | sort | uniq -c | sort -bg >> "$dir_stat""$report"
			echo >> "$dir_stat""$report"
			echo "$temp_buf" | awk '{print $1" "$2}' | sort | uniq -c | sort -bg >> "$dir_stat""$report"
			echo >> "$dir_stat""$report"
			hour=$temp_hour
			begin_hour='1'
			temp_buf=$s

		else

			if [ $c_index -eq '1' ]
			then

				temp_buf=$s

			else

				temp_buf=$(echo -e "$temp_buf\n$s")

			fi


		fi

		let c_index++

	done

	echo "Час $hour:" >>  "$dir_stat""$report"
	echo >>  "$dir_stat""$report"
	echo "$temp_buf" | awk '{print $1}' | sort | uniq -c | sort -bg >>  "$dir_stat""$report"
	echo >> "$dir_stat""$report"
	echo "$temp_buf" | awk '{print $1" "$2}' | sort | uniq -c | sort -bg >> "$dir_stat""$report"

fi
