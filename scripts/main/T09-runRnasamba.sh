#!/usr/bin/bash
# This script is to run timing of rnasamba

### HEAD ###

# opening message
echo " "
echo "For running of timing of rnasamba"

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
softwareName=rnasamba
software=rnasamba
weights=../software/partial_length_weights.hdf5

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"
softwareTimeOut="${runDir}/${softwareName}_times.txt"
errorDir="${runDir}/errors"
runFileList="${runDir}/${softwareName}_files_run.txt"

# Result and other
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"
timingResults="${resultsBase}/${softwareName}_${experiment}_${runName}_timing.txt"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"
timingResultsFileList="${runDir}/timingResultsFileList.txt"

types=("Exons" "OffNeg" "OffPos" "Shuf")

mkdir -p "${resultsDir}"
mkdir -p "${errorDir}"

# clear results file
: > "${resultFileList}"
: > "${softwareTimeOut}"
: > "${runFileList}"

# Array to store timing results
declare -a timingResultsArray=()

#Run on type lists
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
            command_to_run="${software} classify ${outputFile} ${file} ${weights}"
            timing_result=$(reportTime "$command_to_run" "$filename")
            timingResultsArray+=("$timing_result")
            resultFilesArray+=("${outputFile}")
            runFiles+=("${filename}")
        else
            echo "File does not exist: ${file}"
        fi
    done
    wait
    echo "Finished with ${type} type"
done

#write list of results
printf "%s\n" "${resultFilesArray[@]}" > "${resultFileList}"

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
    
    resultDataArray+=("$(awk 'NR==2 {split($1, a, " "); print a[1], $2, $3}' FS='\t' "${file}")")
done

# Default output compile
printf "%s\n" "${resultDataArray[@]}" >> "${compiledResults}".txt

# Output to standardised format
echo "Name,Score,Label" > "${compiledResults}".csv

awk 'BEGIN {OFS=","} {print $1,$2,$3}' "${compiledResults}".txt >> "${compiledResults}".csv
wait