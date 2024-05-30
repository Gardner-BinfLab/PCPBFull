#!/usr/bin/bash
# calculate_kbps.sh

calculate_kbps() {
    start_time=$1
    end_time=$2
    file=$3

    elapsed_time=$(echo "$end_time - $start_time" | bc -l)
    file_size_kb=$(awk '/^>/ {bp+=length($0); next} {bp+=length($0)} END {print bp/1000}' "$file")

    kbps=$(echo "$file_size_kb / $elapsed_time" | bc -l)
    echo "Kilo-bases per second for $file: $kbps"
}
