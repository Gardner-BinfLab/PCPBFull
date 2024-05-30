#!/usr/bin/bash
# This script is to run bioseq2seq

### HEAD ###

# opening message
echo " "
echo "For running of bioseq2seq"

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
validSequenceFilesList="${runDir}/validSequenceFilesList.txt"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"
softwareTimeOut="${runDir}/${softwareName}_times.txt"
errorDir="${runDir}/errors"
runFileList="${runDir}/${softwareName}_files_run.txt"

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

#Run CPC2 on type lists
declare -a runFiles=()
declare -a resultFilesArray=()

readarray -t input_array < "${validSequenceFilesList}"

for file in "${input_array[@]}"; do
    if [ -e "$file" ]; then
        filename=$(basename "${file}" .fa)
        outputFile="${resultsDir}"

        echo "Running ${file}"
        python "${software}" --checkpoint "${checkpoint}" --input "${file}" --output "${outputFile}" &

        resultFilesArray+=("${filename}"_preds.txt)
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

#time taken
echo "script finished"
end_time=$(date +%s)
time_taken=$((end_time - start_time))
echo "Time taken was: ${time_taken} seconds"