#!/bin/bash

#echo "${2}"
dir_lzma="${2%'/'*'7z'}/"

f_name=${2##'/'*'/'}
f_name=${f_name%'.7z'}

dir_ram='/media/ram1/wireshark'
dir_result="${dir_ram}/result/"
dir_main_temp="${dir_ram}/main-temp/"

ran=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20 | xargs)
dir_result_temp="${dir_ram}/result-temp/${ran}/"
mkdir "${dir_result_temp}"

max_next_f='30'
next_f='0'

first_c='1'

frame_num_1="${3}"

f=$(ls -1A -d "${dir_lzma}"*)
num_s_f=$(echo "${f}" | grep -n -e "${2}")
num_s_f=${num_s_f%%':'*'7z'}
end_num_s_f=$(echo "${f}" | wc -l)
#echo "${end_num_s_f}"

while [ 1 ]
do

	if [ ${next_f} -eq ${max_next_f} ]
	then

		echo "${7} Bad call!"
		break

	fi

	let next_f++
	s_f=$(echo "${f}" | sed -n "${num_s_f}p")
	cur_f_name=${s_f##'/'*'/'}
	cur_f_name=${cur_f_name%'.7z'}
#	echo "${s_f}"
	7z x "${s_f}" -o"${dir_result_temp}" &>> /dev/null

	if [ ${first_c} -eq '1' ]
	then

		first_c='0'
		tshark -Y "isup.cic == ${4} && frame.number >= ${frame_num_1}  && ( ( m3ua.protocol_data_opc == ${5} && m3ua.protocol_data_dpc == ${6} ) || \
		( m3ua.protocol_data_opc == ${6} && m3ua.protocol_data_dpc == ${5} ) ) " \
		-r "${dir_result_temp}${cur_f_name}" -F pcapng -w "${dir_result_temp}_${cur_f_name}" 2>/dev/null

	else

		tshark -Y "isup.cic == ${4} && ( ( m3ua.protocol_data_opc == ${5} && m3ua.protocol_data_dpc == ${6} ) || \
		( m3ua.protocol_data_opc == ${6} && m3ua.protocol_data_dpc == ${5} ) ) " \
		-r "${dir_result_temp}${cur_f_name}" -F pcapng -w "${dir_result_temp}_${cur_f_name}" 2>/dev/null

	fi

	rm "${dir_result_temp}${cur_f_name}"
	mv "${dir_result_temp}_${cur_f_name}" "${dir_result_temp}${cur_f_name}"
	ws_out=$(tshark -r "${dir_result_temp}${cur_f_name}" 2>/dev/null)
#	echo "${cur_f_name}"
#	echo "${ws_out}"

	if [ "${ws_out}" == "" ]
	then

		rm "${dir_result_temp}${cur_f_name}"
		let next_f++
		let num_s_f++
		continue

	fi

	next_f='0'

	if [ $(echo "${ws_out}" | grep -c -e "RLC (CIC ${4})") -gt '0' ]
	then

		END_TIME=$(echo "${ws_out}" | grep -m 1 -e "RLC (CIC ${4})" | awk '{print $2}')
		tshark -Y "frame.time_relative <= ${END_TIME}" \
		-r "${dir_result_temp}${cur_f_name}" -F pcapng -w "${dir_result_temp}_${cur_f_name}" 2>/dev/null
		rm "${dir_result_temp}${cur_f_name}"
		mv "${dir_result_temp}_${cur_f_name}" "${dir_result_temp}${cur_f_name}"
		break

	fi

	if [ ${num_s_f} -eq ${end_num_s_f} ]
	then

		echo "${7} End list file!"
		break

	fi

	let num_s_f++

done

f=$(ls -1A "${dir_result_temp}")

if [ $(echo "${f}" | wc -l) -eq '0' ]
then

	rm -rf "${dir_result_temp}"

fi


if [ $(echo "${f}" | wc -l) -eq '1' ]
then

	mv "${dir_result_temp}${f}" "${dir_result}${f_name} $7"
	rm -rf "${dir_result_temp}"

fi

if [ $(echo "${f}" | wc -l) -gt '1' ]
then

	for file in ${f}
	do

		all_file="${all_file} ${dir_result_temp}${file}"

	done

	mergecap -F pcapng -w "${dir_result}${f_name} ${7}" ${all_file}
	rm -rf "${dir_result_temp}"

fi

echo "${f_name}" >> "${dir_main_temp}prog2"

#echo ${3}
