#!/bin/bash

# Takes a list of files and returns their combinded size.

# Check if a file path argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path_to_your_text_file"
    exit 1
fi

# Assign the first argument as the path to the file containing the list of file paths
file_list="$1"

# Initialize total size variable
total_size=0

# Read each line in the file
while IFS= read -r file_path; do
    # Check if the file exists
    if [ ! -f "$file_path" ]; then
        echo "File not found: $file_path"
        continue
    fi

    # Get the size of the file in bytes and add it to total_size
    file_size=$(stat -c%s "$file_path")
    total_size=$((total_size + file_size))
done < "$file_list"

# Convert total size to MB (1 MB = 1048576 bytes)
total_size_mb=$(echo "$total_size / 1048576" | bc -l)

# Output the total size in MB (rounded to 2 decimal places)
printf "Total size: %.2f MB\n" "$total_size_mb"

