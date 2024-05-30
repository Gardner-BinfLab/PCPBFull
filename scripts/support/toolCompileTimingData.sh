#!/usr/bin/bash
# Compilation of timing data

# opening message
echo " "
echo "For compiling of timing data"

# Sanity check for location and correct shell
echo " "
sleep 0.1
read -p "Are you running this in the base project folder? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting"
    echo " "
    exit 1
fi
sleep 0.1

# import config settings
source config/main.config.cfg

### BODY ###

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
sequenceSizes="${runDir}/sequenceSizes.txt"
timingResults="${runDir}/timingResultsFileList.txt"

# Clear with sizes files
while IFS= read -r timingFilePath; do
    # Wipe with sizes first
    : > "${timingFilePath%.txt}_with_sizes.txt"
done < "${timingResults}"

# Loop through each line in sequenceSizes.txt
while IFS="," read -r seqName seqSize gcContent; do
    # Read each file path from timingResults.txt
    while IFS= read -r timingFilePath; do
        # Use grep to search for the pattern in the timing data file
        # If a match is found, append the sequence size to the line
        echo "Working on ${timingFilePath}"
        grep "$seqName" "$timingFilePath" | while IFS= read -r line; do
            echo "$line,$seqSize" >> "${timingFilePath%.txt}_with_sizes.txt"
        done
    done < "${timingResults}"
done < "${sequenceSizes}"
