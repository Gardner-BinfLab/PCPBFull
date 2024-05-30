#!/usr/bin/bash
# This script is to run CPC2 timing

### HEAD ###

# opening message
echo " "
echo "For running of CPC2 timing"

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

# import experiment & run settings
source scripts/support/toolGetExperiment.sh
source config/config_"$experiment_ID".cfg


### BODY ###
#set vars
# software
softwareName=CPC2
software="../software/CPC2_standalone/bin/CPC2.py"

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"
errorDir="${runDir}/errors"
runFileList="${runDir}/CPC2_files_run.txt"
timingResultsFileList="${runDir}/timingResultsFileList.txt"

# Result and other
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"
timingResults="${resultsBase}/${softwareName}_${experiment}_${runName}_timing.txt"
types=("Exons" "OffNeg" "OffPos" "Shuf")

mkdir -p "${resultsDir}"
mkdir -p "${errorDir}"

# clear results file
: > "${resultFileList}"

: > "${runFileList}"

#Run CPC2 on type lists
# Array to store timing results
declare -a timingResultsArray=()
declare -a runFiles=()
declare -a resultFilesArray=()

for type in "${types[@]}"; do
    sequenceFileList="${runDir}/sequenceFileList_${type}.txt"
    readarray -t input_array < "${sequenceFileList}"


    for file in "${input_array[@]}"; do
        if [ -e "$file" ]; then
            filename=$(basename "${file}" .fa)
            outputFile="${resultsDir}/${filename}_${softwareName}_Result"
            echo "Running ${file}"
            command_to_run="python3 \"${software}\" --ORF -i \"${file}\" -o \"${outputFile}\""
            timing_result=$(reportTime "$command_to_run" "$filename")
            timingResultsArray+=("$timing_result")
            resultFilesArray+=("${outputFile}.txt")
            runFiles+=("${filename}")
        else
            echo "File does not exist: ${file}"
        fi
    done
    wait
    echo "Finished with ${type} type"

done

#write list of results
printf "%s\n" "${resultFilesArray[@]}" >> "${resultFileList}"

# Write timing data
printf "%s\n" "${timingResultsArray[@]}" > "${timingResults}"

echo "${timingResults}" >> "${timingResultsFileList}"

echo "Finished running ${softwareName}"
echo "Now compiling results"
sleep 1

# Write file processed log
echo "${runFiles[@]}" >> "${runFileList}"

wait

#compile results
: > "${compiledResults}".txt
declare -a resultDataArray=()

readarray -t allResultFilesArray < "${resultFileList}"
for file in "${allResultFilesArray[@]}"; do
    
    resultDataArray+=("$(sed -n '2p' "${file}")")
done

# Default output compile
printf "%s\n" "${resultDataArray[@]}" >> "${compiledResults}".txt

# Output to standardised format
echo "Name,Score,Start,End,Fickett,pI,ORF_integrity,Label" > "${compiledResults}".csv

awk 'BEGIN {OFS=","} {print $1,$8,$7,$3*3+$7-1,$4,$5,$6,$9}' "${compiledResults}".txt >> "${compiledResults}".csv

wait
