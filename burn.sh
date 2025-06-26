#!/bin/bash

if [ "$#" -lt 1 ]; then 
  echo "Usage: " $0 " /path/to/directory/with/wav/files"
  exit 1
fi

if [ ! -d "$1" ]; then
    echo "Error: Directory '$1' not found"
    exit 1
fi

shopt -s nullglob
# this will sort the files semantically so label them 00_song, 01_song...
mapfile -t files < <(find "$1" -maxdepth 1 -iname '*.wav' | sort)

if [ ${#files[@]} -eq 0 ]; then
    echo "Error: No WAV files found in '$1'"
    exit 1
fi

printf '%s\n' "${files[@]}"

cdrecord -v -dao -audio -pad -overburn "${files[@]}"
