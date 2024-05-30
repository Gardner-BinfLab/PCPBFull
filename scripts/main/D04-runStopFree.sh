#!/usr/bin/bash
# This script is to run in-house stop free finder

### HEAD ###

# opening message
echo " "
echo "For running of in-house stopFree finder"

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
softwareFolder="scripts/support"
software="${softwareFolder}/toolStopFreeFinder.py"
softwareName="stopFree"

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"
validSequenceFilesList="${runDir}/validSequenceFilesList.txt"

# Result and other
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"

mkdir -p "$resultsDir"
mkdir -p "$resultsDir"

: > "${resultFileList}"


### main code run ###
#set timer
start_time=$(date +%s)


echo " "

declare -a resultFilesArray=()

# Run stopFree on type lists
readarray -t input_array < "$validSequenceFilesList"

for file in "${input_array[@]}"; do
    filename=$(basename "$file" .fa)
    outputFile="${resultsDir}/${filename}_${softwareName}_Result"

    if [[ -e "$file" ]]; then
        echo "running on ${filename}"
        python3 "$software" "${file}" "${outputFile}" &
        resultFilesArray+=("${outputFile}")
    else
        echo "${file} does not exist"
    fi
    pwait "$choketime"
done
wait
#write list of results per type
printf "%s\n" "${resultFilesArray[@]}" >> "$resultFileList"

#compile results
declare -a output_array=()
: > "$compiledResults".csv
for file in "${resultFilesArray[@]}"; do
    
    output_array+=("$(sed -n '1,3p' "$file")")
done

printf "%s\n" "${output_array[@]}" > "$compiledResults".txt

echo "Name,Score,Start,End," > "$compiledResults".csv
awk -F "," 'BEGIN {OFS=","}{print $1,$6,$4,$5}' "${compiledResults}".txt >> "${compiledResults}".csv

wait
cp "${compiledResults}".csv "${compiledResultsFolder}"

#time taken
echo "script finished"
end_time=$(date +%s)
time_taken=$((end_time - start_time))
echo "Time taken was: ${time_taken} seconds"
