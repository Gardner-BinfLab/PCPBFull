#!/usr/bin/bash
# This script is to run CPPred

### HEAD ###

# opening message
echo " "
echo "For running of CPPred"

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

 
##### Currently CPPred doesn't like to run more than one instance at once.
# I could try and edit the python...

# Process choke. Creates function to allow number of process limits
# read -rp "How many processes do you want to spawn at once? " choketime

# function pwait() {
#     while [ "$(jobs -p | wc -l)" -ge "$1" ]; do
#         sleep 2
#     done
# }
# sleep 0.1

### BODY ###
 
#set vars
# software
softwareName=CPPred
softwareFolder="../software/CPPred"
software="${softwareFolder}/bin/CPPred.py"

# Run list data specific
runDir="data/runs/${experiment}/${runName}"
resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"
errorDir="${runDir}/errors"
validSequenceFilesList="${runDir}/validSequenceFilesList.txt"

# Result and other
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"
runFileList="${runDir}/${softwareName}_files_run.txt"

mkdir -p "${resultsDir}"
mkdir -p "${errorDir}"

#set timer
start_time=$(date +%s)

: > "${resultFileList}"

declare -a runFiles=()
declare -a resultFilesArray=()

#Run CPPred
readarray -t input_array < "${validSequenceFilesList}"

for file in "${input_array[@]}"; do
    if [ -e "${file}" ]; then
    filename=$(basename "$file" .fa)
    outputFile="${resultsDir}/${filename}_${softwareName}_Result"
    errorFile="${errorDir}/${filename}_${softwareName}_Error.log"

    echo "Running ${filename}"
    python2.7 "${software}" -i "${file}" -hex "${softwareFolder}/Hexamer/Integrated_Hexamer.tsv" -r "${softwareFolder}/Integrated_Model/Integrated.range" -mol "${softwareFolder}/Integrated_Model/Integrated.model" -spe Integrated -o "${outputFile}" 2>>"${errorFile}"
    resultFilesArray+=("${outputFile}")
    runFiles+=("${filename}")
    #pwait "${choketime}"
    wait
    else
    echo "File ${file} doesn't exist"
    fi
done
wait


#compile results
printf "%s\n" "${resultFilesArray[@]}" >> "${resultFileList}"

# Write file processed log
printf "%s\n" "${runFiles[@]}" >> "${runFileList}"
wait

declare -a output_array=()

: > "${compiledResults}".csv
: > "${compiledResults}".txt

readarray -t allResultFilesArray < "${resultFileList}"

for file in "${allResultFilesArray[@]}"; do
    if [[ -e "${file}" ]]; then
    output_array+=("$(sed -n '2p' "$file")")
    else
    echo "Missing result: $file"
    fi
done

printf "%s\n" "${output_array[@]}" >> "${compiledResults}".txt
echo "Name,Score,Start,End,Fickett,pI,ORF_integrity,Label" > "${compiledResults}".csv
awk 'BEGIN {OFS=","}{print $1,$41,"none","none",$8,$11,$3,$40}' "${compiledResults}".txt >> "${compiledResults}".csv

wait
cp "${compiledResults}".csv "${compiledResultsFolder}"

#time taken
echo "script finished"
end_time=$(date +%s)
time_taken=$((end_time - start_time))
echo "Time taken was: ${time_taken} seconds"





