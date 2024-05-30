#!/usr/bin/bash
# This script is to run LGC

### HEAD ###

# opening message
echo " "
echo "For running of LGC"

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
softwareName=LGC
softwareFolder="../software"
software="${softwareFolder}/bin/LGC-1.0.py"

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"
validSequenceFilesList="${runDir}/validSequenceFilesList.txt"

# Result and other
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"
mkdir -p "${resultsDir}"

#set timer
start_time=$(date +%s)

: > "${resultFileList}"

readarray -t input_array < "${validSequenceFilesList}"

declare -a resultFilesArray=()

for file in "${input_array[@]}"; do
    if [ -e "${file}" ]; then
    filename=$(basename "$file" .fa)
    outputFile="${resultsDir}/${filename}_${softwareName}_Result"

    python2.7 "${software}" "${file}" "${outputFile}"
    resultFilesArray+=("${outputFile}")
    wait
    else
    echo "File ${file} doesn't exist"
    fi
done
wait

#write list of results
printf "%s\n" "${resultFilesArray[@]}" >> "${resultFileList}"

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

wait
cp "${compiledResults}".csv "${compiledResultsFolder}"

#time taken
echo "script finished"
end_time=$(date +%s)
time_taken=$((end_time - start_time))
echo "Time taken was: ${time_taken} seconds"





