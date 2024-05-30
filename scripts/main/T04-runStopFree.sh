#!/usr/bin/bash
# This script is to run in-house stop free finder
# With timing

### HEAD ###

# opening message
echo " "
echo "For running of in-house stopFree finder with timing"

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
#set vars
# software
softwareFolder="scripts/support"
software="${softwareFolder}/toolStopFreeFinder.py"
softwareName="stopFree"

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"

# Result and other
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"
compiledResultsFolder="${resultsBase}"
timingResults="${resultsBase}/${softwareName}_${experiment}_${runName}_timing.txt"
timingResultsFileList="${runDir}/timingResultsFileList.txt"

mkdir -p "$resultsDir"

: > "${resultFileList}"


### main code run ###
echo " "

types=("Exons" "OffNeg" "OffPos" "Shuf")
declare -a resultFilesArray=()

# Array to store timing results
declare -a timingResultsArray=()

# Run stopFree on type lists
for type in "${types[@]}"; do
    sequenceFileList="data/runs/${experiment}/${runName}/sequenceFileList_${type}.txt"
    readarray -t input_array < "$sequenceFileList"

    for file in "${input_array[@]}"; do
        filename=$(basename "$file" .fa)
        outputFile="${resultsDir}/${filename}_${softwareName}_Result"

        if [[ -e "$file" ]]; then
            echo "running on ${filename}"
            command_to_run="python3 \"$software\" \"${file}\" \"${outputFile}\""
            timing_result=$(reportTime "$command_to_run" "$filename")
            timingResultsArray+=("$timing_result")
            resultFilesArray+=("${outputFile}")
        else
            echo "${file} does not exist"
        fi
    done
    wait
done
wait

#write list of results
printf "%s\n" "${resultFilesArray[@]}" > "$resultFileList"

# Write timing data
printf "%s\n" "${timingResultsArray[@]}" > "${timingResults}"
echo "${timingResults}" >> "${timingResultsFileList}"

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
