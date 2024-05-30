#!/usr/bin/bash
# This script is to run randomClassify

### HEAD ###

# opening message
echo " "
echo "For running of randomClassify"

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

 
# Process choke. Creates function to allow number of process limits
read -rp "How many processes do you want to spawn at once? " choketime

function pwait() {
    while [ "$(jobs -p | wc -l)" -ge "$1" ]; do
        sleep 2
    done
}
sleep 0.1


### BODY ###
 
#set vars
# software
softwareName=randomClassify
software=randomClassify

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
validSequenceFilesList="${runDir}/validSequenceFilesList.txt"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"
errorDir="${runDir}/errors"
runFileList="${runDir}/${softwareName}_files_run.txt"

# Result and other
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"

mkdir -p "${resultsDir}"
mkdir -p "${errorDir}"

# clear results file
: > "${resultFileList}"
: > "${runFileList}"

#Run CPC2 on type lists
declare -a runFiles=()
declare -a resultFilesArray=()

readarray -t input_array < "${validSequenceFilesList}"

for file in "${input_array[@]}"; do
    if [ -e "$file" ]; then
        filename=$(basename "${file}" .fa)
        outputFile="${resultsDir}/${filename}_${softwareName}_Result"

        # Generate a random number between 1 and 100
        randomScore=$((1 + RANDOM % 100))

        echo "Running ${file}"
        echo "${filename} ${randomScore}" > "${outputFile}" &

        resultFilesArray+=("${outputFile}")
        runFiles+=("${filename}")
        pwait "${choketime}"
    else
        echo "File does not exist: ${file}"
    fi
done
wait

echo "Finished running ${softwareName}"
echo "Now compiling results"

printf "%s\n" "${resultFilesArray[@]}" >> "${resultFileList}"
sleep 1

# Write file processed log
printf "%s\n" "${runFiles[@]}" >> "${runFileList}"
wait

#compile results
: > "${compiledResults}".txt
declare -a resultDataArray=()

readarray -t allResultFilesArray < "${resultFileList}"
for file in "${allResultFilesArray[@]}"; do
    
    resultDataArray+=("$(cat "${file}")")
done

# Default output compile
printf "%s\n" "${resultDataArray[@]}" >> "${compiledResults}".txt

# Output to standardised format
echo "Name,Score" > "${compiledResults}".csv

awk 'BEGIN {OFS=","} {print $1,$2}' "${compiledResults}".txt >> "${compiledResults}".csv
wait

cp "${compiledResults}".csv "${compiledResultsFolder}"

echo "Done"