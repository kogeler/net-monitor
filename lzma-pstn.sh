#!/bin/bash

dir_lzma='/media/data/wireshark/'
dir_lzma_pstn="$dir_lzma"'lzma-pstn/'

dir_ram='/media/ram1/wireshark/'
dir_lzma_temp_pstn="$dir_ram"'lzma-temp-pstn/'
dir_lzma_lock_pstn="$dir_ram"'lzma-lock-pstn/'

file_lock="$dir_lzma_lock_pstn""$1"

echo "$$" > "$file_lock"

tshark -Y 'sctp || mgcp || sip || iua' -r "$dir_lzma_temp_pstn""$1" -F pcapng -w "$dir_lzma_temp_pstn""$1"'_cleaned_1'
rm "$dir_lzma_temp_pstn""$1"

mv "$dir_lzma_temp_pstn""$1"'_cleaned_1' "$dir_lzma_temp_pstn""$1"
7z a "$dir_lzma_temp_pstn""$1"'.7z' "$dir_lzma_temp_pstn""$1" -t7z -m0=LZMA2 -mx=9 -mmt
mv "$dir_lzma_temp_pstn""$1"'.7z' "$dir_lzma_pstn""$1"'.7z'
chmod a=rw "$dir_lzma_pstn""$1"'.7z'
rm "$dir_lzma_temp_pstn""$1"

rm "$file_lock"
