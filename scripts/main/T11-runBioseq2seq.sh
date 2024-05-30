#!/usr/bin/bash
# This script is to run timing of bioseq2seq

### HEAD ###

# opening message
echo " "
echo "For running timing of bioseq2seq"

# Sanity check for location and correct shell
echo " "
sleep 0.1
read -p "Are you running this in the base project folder and are you running this in the python env? " -n 1 -r
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
softwareName=bioseq2seq
software=../software/bioseq2seq/bioseq2seq/bin/translate.py
checkpoint=../software/bioseq2seq/best_bioseq2seq-wt_LFN_mammalian_200-1200.pt

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
            command_to_run="python ${software} --checkpoint ${checkpoint} --input ${file} --output ${outputFile}"
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
    
    resultDataArray+=("$(awk -F'[ :]' '{if (NR == 1) { 
                                            gene=$3; 
                                            prob=$7; 
                                        }else if (NR == 2) { 
                                            pred=$3; 
                                            if (pred == "<NC>") pred = "noncoding";
                                            else if (pred == "<PC>") pred = "coding";
                                            print gene, prob, pred; 
                                            }
                                        }' "${resultsDir}/${file}")")
done

# Default output compile
printf "%s\n" "${resultDataArray[@]}" >> "${compiledResults}".txt

# Output to standardised format
echo "Name,Score,Label" > "${compiledResults}".csv

awk 'BEGIN {OFS=","} {print $1,$2,$3}' "${compiledResults}".txt >> "${compiledResults}".csv
wait

cp "${compiledResults}".csv "${compiledResultsFolder}"