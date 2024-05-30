#!/usr/bin/bash
# This script is to run PhyloCSF

### HEAD ###

# opening message
echo " "
echo "For running of PhyloCSF"

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
softwareName=PhyloCSF
software=PhyloCSF

# Run specific vars
runDir="data/runs/${experiment}/${runName}"
afaList="${runDir}/afaEditedFilesList.txt"
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"

resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"
timingResults="${resultsBase}/${softwareName}_${experiment}_${runName}_timing.txt"
timingResultsFileList="${runDir}/timingResultsFileList.txt"

mkdir -p "$resultsDir"

# Array to store timing results
declare -a timingResultsArray=()

# Declare an empty array
echo "creating empty array"
declare -a fullList=()

# Read the files line by line and append each line as an element in the array
echo "filling array with aligned fasta files"
while IFS= read -r line; do
    fullList+=("$line")
done < "$afaList"

: > "${resultFileList}"

# Run through array of files and run software
echo "creating output array"
declare -a output_array=()

echo "running PhyloCsf"
for file in "${fullList[@]}"; do
    filename=$(basename "$file" .fa)
    outputFile="${resultsDir}/${filename}_${softwareName}_Result"
    details="-f6 --removeRefGaps --strategy=omega ${experiment} ${file}"

    echo "Running on ${filename}"
    command_to_run="${software} ${details}"
    timing_result=$(reportTime "$command_to_run" "$outputFile" "$filename")
    timingResultsArray+=("$timing_result")
    output_array+=("${outputFile}")
done
wait

#write list of results
printf "%s\n" "${output_array[@]}" > "${resultFileList}"

# Write timing data
printf "%s\n" "${timingResultsArray[@]}" > "${timingResults}"
echo "${timingResults}" >> "${timingResultsFileList}"

wait

#compile results
declare -a output_array=()
: > "${compiledResults}".csv
: > "${compiledResults}".txt
readarray -t allResultFilesArray < "${resultFileList}"
for file in "${allResultFilesArray[@]}"; do
    
    output_array+=("$(awk '{split($1,a,"/"); print a[6] " " $3}' "$file")")
done

printf "%s\n" "${output_array[@]}" > "${compiledResults}".txt
echo "Name,Score,Start,End" > "${compiledResults}".csv
awk 'BEGIN {OFS=","}{print $1, $2,"none","none"}' "${compiledResults}".txt >> "${compiledResults}".csv
