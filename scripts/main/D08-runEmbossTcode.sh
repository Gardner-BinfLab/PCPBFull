#!/usr/bin/bash
# This script is to run Emboss tcode

### HEAD ###

# opening message
echo " "
echo "For running of Emboss tcode"

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
softwareName=tcode
software="tcode"

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"
softwareTimeOut="${runDir}/${softwareName}_times.txt"
errorDir="${runDir}/errors"
runFileList="${runDir}/${softwareName}_files_run.txt"
validSequenceFilesList="${runDir}/validSequenceFilesList.txt"

# Result and other
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"

mkdir -p "${resultsDir}"
mkdir -p "${errorDir}"

#set timer
start_time=$(date +%s)

# clear results file
: > "${resultFileList}"
: > "${softwareTimeOut}"
: > "${runFileList}"

#Run on type lists
declare -a runFiles=()

readarray -t input_array < "${validSequenceFilesList}"
declare -a resultFilesArray=()

for file in "${input_array[@]}"; do
    if [ -e "$file" ]; then
        filename=$(basename "${file}" .fa)
        outputFile="${resultsDir}/${filename}_${softwareName}_Result"

        echo "Running ${file}"
        "${software}" -window 200 -outfile "${outputFile}" "${file}" &

        resultFilesArray+=("${outputFile}")
        runFiles+=("${filename}")
        pwait "${choketime}"
    else
        echo "File does not exist: ${file}"
    fi
done
wait
printf "%s\n" "${resultFilesArray[@]}" >> "${resultFileList}"

echo "Finished running ${softwareName}"
echo "Now compiling results"
sleep 1
# Write file processed log

printf "%s\n" "${runFiles[@]}" >> "${runFileList}"

wait

# compile results
: > "${compiledResults}".txt
declare -a resultDataArray=()

readarray -t allResultFilesArray < "${resultFileList}"
for file in "${allResultFilesArray[@]}"; do
    # Reset max_score for each file
    max_score=-1
    # Run awk script on the file and append output to the array
    resultDataArray+=("$(awk -v max_score="$max_score" 'BEGIN {OFS=","}
        /Sequence:/ { sequence_name = $3 }
        /^  Start/ { capture = 1 }
        /^#-/ { capture = 0 }

        {
        if (capture && $0 !~ /^  Start/) {
            if ($4 > max_score) {
            max_score = $4
            max_score_line = $1 "," $2"," $3"," $4"," $5
            }
        }
        }

        END {
        print sequence_name, max_score_line
        }
        ' "${file}")")
done

# Default output compile
printf "%s\n" "${resultDataArray[@]}" >> "${compiledResults}".txt

# Output to standardised format
echo "Name,Score,Start,End,Label" > "${compiledResults}".csv

awk 'BEGIN {OFS=","; FS=","} {print $1,$5,$2,$3,$6}' "${compiledResults}".txt >> "${compiledResults}".csv

wait
cp "${compiledResults}".csv "${compiledResultsFolder}"

# time taken
echo "script finished"
end_time=$(date +%s)
time_taken=$((end_time - start_time))
echo "Time taken was: ${time_taken} seconds"