#!/bin/bash

dir_scripts='/opt/net-monitor/'
dir_lzma='/media/data/wireshark/'
dir_lzma_mobile="$dir_lzma"'lzma-mobile/'
dir_lzma_mobile_radio="$dir_lzma"'lzma-mobile-radio/'
dir_lzma_pstn="$dir_lzma"'lzma-pstn/'

dir_ram='/media/ram1/wireshark/'

dir_raw_mobile="$dir_ram"'raw-mobile/'
dir_raw_pstn="$dir_ram"'raw-pstn/'

dir_lzma_temp_mobile="$dir_ram"'lzma-temp-mobile/'
dir_lzma_lock_mobile="$dir_ram"'lzma-lock-mobile/'

dir_lzma_temp_pstn="$dir_ram"'lzma-temp-pstn/'
dir_lzma_lock_pstn="$dir_ram"'lzma-lock-pstn/'

dir_unlzma="$dir_ram"'unlzma/'
dir_unlzma_lock="$dir_ram"'unlzma-lock/'
dir_result="$dir_ram"'result/'
dir_result_temp="$dir_ram"'result-temp/'
dir_main_temp="$dir_ram"'main-temp/'
dir_temp="$dir_ram"'temp/'

if [ ! -d "$dir_ram" ]
then

	mkdir -m 777 "$dir_ram"

fi

if [ ! -d "$dir_lzma_temp_mobile" ]
then

	mkdir -m 777 "$dir_lzma_temp_mobile"

fi

if [ ! -d "$dir_lzma_lock_mobile" ]
then

	mkdir -m 777 "$dir_lzma_lock_mobile"

fi

if [ ! -d "$dir_lzma_temp_pstn" ]
then

	mkdir -m 777 "$dir_lzma_temp_pstn"

fi

if [ ! -d "$dir_lzma_lock_pstn" ]
then

	mkdir -m 777 "$dir_lzma_lock_pstn"

fi

if [ ! -d "$dir_unlzma" ]
then

	mkdir -m 777 "$dir_unlzma"

fi

if [ ! -d "$dir_unlzma_lock" ]
then

	mkdir -m 777 "$dir_unlzma_lock"

fi

if [ ! -d "$dir_result" ]
then

	mkdir -m 777 "$dir_result"

fi

if [ ! -d "$dir_result_temp" ]
then

	mkdir -m 777 "$dir_result_temp"

fi

if [ ! -d "$dir_main_temp" ]
then

	mkdir -m 777 "$dir_main_temp"

fi

if [ ! -d "$dir_temp" ]
then

	mkdir -m 777 "$dir_temp"

fi

find "$dir_lzma_temp_mobile" -maxdepth 1 -type f -delete &>> /dev/null
find "$dir_lzma_lock_mobile" -maxdepth 1 -type f -delete &>> /dev/null
find "$dir_lzma_temp_pstn" -maxdepth 1 -type f -delete &>> /dev/null
find "$dir_lzma_lock_pstn" -maxdepth 1 -type f -delete &>> /dev/null

while [ 1 ]
do

	f=$(ls -1A "$dir_raw_mobile")

	if [ $(echo "$f" | wc -l) -ge '2' ] && [ $(ls -1A "$dir_lzma_lock_mobile" | wc -l) -lt '3' ]
	then

		rm $(find "$dir_lzma_mobile" | sort | sed -n '2p')
		rm $(find "$dir_lzma_mobile_radio" | sort | sed -n '2p')
		file_temp=$(echo "$f" | sort -k 1.11 | sed -n '1p')
		mv "$dir_raw_mobile""$file_temp" "$dir_lzma_temp_mobile"${file_temp:11}
		"$dir_scripts"'lzma-mobile.sh' ${file_temp:11} &

	fi

	f=$(ls -1A "${dir_raw_pstn}")

	if [ $(echo "${f}" | grep 'vlg' | wc -l) -ge '2' ] && [ $(ls -1A "${dir_lzma_lock_pstn}" | wc -l) -lt '3' ]
	then

		rm $(find "$dir_lzma_pstn" | grep 'vlg' | sort | sed -n '1p')
		file_temp=$(echo "${f}" | grep 'vlg' | sort -k 1.10 | sed -n '1p')
		f_name="vlg_${file_temp:10:18}"
		mv "${dir_raw_pstn}${file_temp}" "${dir_lzma_temp_pstn}${f_name}"
		"${dir_scripts}lzma-pstn.sh" ${f_name} &

	fi

	if [ $(echo "${f}" | grep 'chr' | wc -l) -ge '2' ] && [ $(ls -1A "${dir_lzma_lock_pstn}" | wc -l) -lt '3' ]
	then

		rm $(find "$dir_lzma_pstn" | grep 'chr' | sort | sed -n '1p')
		file_temp=$(echo "${f}" | grep 'chr' | sort -k 1.10 | sed -n '1p')
		f_name="chr_${file_temp:10:18}"
		mv "${dir_raw_pstn}${file_temp}" "${dir_lzma_temp_pstn}${f_name}"
		"${dir_scripts}lzma-pstn.sh" ${f_name} &

	fi

	if [ `df -B M | grep "/dev/mapper/vg00-lv00" | awk '{print $4}' | sed 's/M//'` -le '2000' ]
	then

		#echo "delete"
		rm $(find "$dir_lzma_mobile" | sort | sed -n '2p')
		rm $(find "$dir_lzma_mobile_radio" | sort | sed -n '2p')
		rm $(find "$dir_lzma_pstn" | grep 'vlg' | sort | sed -n '1p')
		rm $(find "$dir_lzma_pstn" | grep 'chr' | sort | sed -n '1p')

	fi

	sleep 1

done
