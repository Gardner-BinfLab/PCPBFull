#!/bin/bash

# Default to the current directory if no directory is provided
directory=${1:-.}

# Count the number of files in the directory and its subdirectories
file_count=$(find "$directory" -type f | wc -l)

# Output the result
echo "Total number of files in '$directory': $file_count"
