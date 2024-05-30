#!/usr/bin/bash
# This script is to run esl-translate on extracted fasta regions

### HEAD ###

# opening message
echo " "
echo "For running of esl-translate on extracted fasta regions"

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
software="esl-translate"
softwareName="esl-translate"

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"

# Result and other
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"

mkdir -p "$resultsDir"
mkdir -p "$resultsDir"

: > "${resultFileList}"


### main code run ###
echo " "

types=("Exons" "OffNeg" "OffPos" "Shuf")
declare -a resultFilesArray=()

# Run software on type lists
for type in "${types[@]}"; do
    sequenceFileList="data/runs/${experiment}/${runName}/sequenceFileList_${type}.txt"
    readarray -t input_array < "$sequenceFileList"

    for file in "${input_array[@]}"; do
        filename=$(basename "$file" .fa)
        outputFile="${resultsDir}/${filename}_${softwareName}_Result"

        if [[ -e "$file" ]]; then
            echo "running on ${filename}"
            esl-translate "${file}" > "${outputFile}" &
            resultFilesArray+=("${outputFile}")
        else
            echo "${file} does not exist"
        fi
        pwait "$choketime"
    done
    wait
    #write list of results per type
    printf "%s\n" "${resultFilesArray[@]}" >> "$resultFileList"
done
wait

#compile results
awkFunction="scripts/support/functionExtractOrf.awk"
declare -a output_array=()
for file in "${resultFilesArray[@]}"; do
    output_array+=("$(awk -f "${awkFunction}" "${file}")")
done

printf "%s\n" "${output_array[@]}" > "$compiledResults".txt

#compile summary
awkFunction2="scripts/support/functionExtractOrfSummary.awk"
: > "$compiledResults".csv
awk -f "${awkFunction2}" "$compiledResults".txt > "$compiledResults".csv
