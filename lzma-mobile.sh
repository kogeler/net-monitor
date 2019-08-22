#!/bin/bash

dir_lzma='/media/data/wireshark/'
dir_lzma_mobile="$dir_lzma"'lzma-mobile/'
dir_lzma_mobile_radio="$dir_lzma"'lzma-mobile-radio/'

dir_ram='/media/ram1/wireshark/'
dir_lzma_temp_mobile="$dir_ram"'lzma-temp-mobile/'
dir_lzma_lock_mobile="$dir_ram"'lzma-lock-mobile/'

file_lock="$dir_lzma_lock_mobile""$1"

echo "$$" > "$file_lock"

tshark -Y 'isup || camel || inap || gsm_map || bicc || tcap.abort_element || tcap.end_element' -r "$dir_lzma_temp_mobile""$1" -F pcapng -w "$dir_lzma_temp_mobile""$1"'_cleaned_1'
tshark -Y 'bssap || ranap || sccp.message_type == 0x02 || sccp.message_type == 0x04 || sccp.message_type == 0x05' -r "$dir_lzma_temp_mobile""$1" -F pcapng -w "$dir_lzma_temp_mobile""$1"'_cleaned_2'
rm "$dir_lzma_temp_mobile""$1"

mv "$dir_lzma_temp_mobile""$1"'_cleaned_1' "$dir_lzma_temp_mobile""$1"
7z a "$dir_lzma_temp_mobile""$1"'.7z' "$dir_lzma_temp_mobile""$1" -t7z -m0=LZMA2 -mx=9 -mmt
mv "$dir_lzma_temp_mobile""$1"'.7z' "$dir_lzma_mobile""$1"'.7z'
chmod a=rw "$dir_lzma_mobile""$1"'.7z'
rm "$dir_lzma_temp_mobile""$1"

mv "$dir_lzma_temp_mobile""$1"'_cleaned_2' "$dir_lzma_temp_mobile""$1"
7z a "$dir_lzma_temp_mobile""$1"'.7z' "$dir_lzma_temp_mobile""$1" -t7z -m0=LZMA2 -mx=9 -mmt
mv "$dir_lzma_temp_mobile""$1"'.7z' "$dir_lzma_mobile_radio""$1"'.7z'
chmod a=rw "$dir_lzma_mobile_radio""$1"'.7z'
rm "$dir_lzma_temp_mobile""$1"

rm "$file_lock"
