#!/usr/bin/bash
# This script is to run LGC for timing

### HEAD ###

# opening message
echo " "
echo "For running of LGC timing"

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
softwareName=LGC
softwareFolder="../software"
software="${softwareFolder}/bin/LGC-1.0.py"

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"

# Result and other
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"
timingResults="${resultsBase}/${softwareName}_${experiment}_${runName}_timing.txt"
timingResultsFileList="${runDir}/timingResultsFileList.txt"

mkdir -p "${resultsDir}"

: > "${resultFileList}"

types=("Exons" "OffNeg" "OffPos" "Shuf")

declare -a resultFilesArray=()

# Array to store timing results
declare -a timingResultsArray=()

#Run CPPred on type lists
for type in "${types[@]}"; do
    sequenceFileList="${runDir}/sequenceFileList_${type}.txt"
    readarray -t input_array < "${sequenceFileList}"

    for file in "${input_array[@]}"; do
        if [ -e "${file}" ]; then
        filename=$(basename "$file" .fa)
        outputFile="${resultsDir}/${filename}_${softwareName}_Result"
        echo "running on ${filename}"
        command_to_run="python2.7 \"${software}\" \"${file}\" \"${outputFile}\""
        timing_result=$(reportTime "$command_to_run" "$filename")
        timingResultsArray+=("$timing_result")
        resultFilesArray+=("${outputFile}")
        wait
        else
        echo "File ${file} doesn't exist"
        fi
    done
    wait
done
wait

#write list of results
printf "%s\n" "${resultFilesArray[@]}" >> "${resultFileList}"

# Write timing data
printf "%s\n" "${timingResultsArray[@]}" > "${timingResults}"
echo "${timingResults}" >> "${timingResultsFileList}"

#compile results
declare -a output_array=()
: > "${compiledResults}".csv
: > "${compiledResults}".txt
readarray -t allResultFilesArray < "${resultFileList}"
for file in "${allResultFilesArray[@]}"; do
    
    output_array+=("$(sed -n '12p' "$file")")
done

printf "%s\n" "${output_array[@]}" >> "${compiledResults}".txt
echo "Name,Score,Start,End,Label" > "${compiledResults}".csv
awk -F "\t" 'BEGIN {OFS=","}{print $1, $4, "none", "none", $5}' "${compiledResults}".txt >> "${compiledResults}".csv
