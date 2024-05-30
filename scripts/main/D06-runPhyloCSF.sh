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
softwareName=PhyloCSF
software=PhyloCSF

# Run specific vars
runDir="data/runs/${experiment}/${runName}"
afaList="${runDir}/afaEditedFilesList.txt"
resultsBase="results/${softwareName}/${experiment}"
resultsDir="${resultsBase}/${runName}"

resultFileList="${runDir}/${experiment}_${runName}_${softwareName}_ResultFileList.txt"
compiledResults="${resultsBase}/${softwareName}_${experiment}_${runName}_compiled"
mkdir -p "$resultsDir"

#set timer
start_time=$(date +%s)

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

    echo "running on ${filename}"
    "${software}" "${details}" > "${outputFile}" &
    output_array+=("${outputFile}")
    pwait "$choketime"
done
wait
#write list of results per type
printf "%s\n" "${output_array[@]}" >> "${resultFileList}"

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

wait

cp "${compiledResults}".csv "${compiledResultsFolder}"

#time taken
echo "script finished"
end_time=$(date +%s)
time_taken=$((end_time - start_time))
echo "Time taken to run program: ${time_taken} seconds"