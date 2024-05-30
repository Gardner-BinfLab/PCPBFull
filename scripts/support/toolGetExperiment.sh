#!/bin/bash

# For experiment choosing

# Directory containing the text files
directory="speciesLists/"

# Create an array to hold the filenames without extensions
options=()

# Iterate through the text files in the directory, stripping the extension
for file in "${directory}"*.txt; do
  filename=$(basename -- "$file" .txt)
  options+=("$filename")
done

# Display the options to the user
echo "Please select an experiment ID:"
select option in "${options[@]}"; do
  if [ -n "$option" ]; then
    experiment_ID="$option"
    break
  else
    echo "Invalid selection. Please try again."
  fi
done

# Export the variable so it's accessible to the parent script
export experiment_ID
