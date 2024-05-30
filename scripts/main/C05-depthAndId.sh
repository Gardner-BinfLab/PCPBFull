#!/bin/bash

# Creates a file of alidepth and percent id

# opening message
echo " "
echo "For creating alidepth and percent id"

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
# get run configuration
 
runDir="data/runs/${experiment}/${runName}"
resultDir="results/esl-alistat/${experiment}/${runName}"
mkdir -p "${resultDir}"

# Var
alignedFilesList="${runDir}/alignedFilesList.txt"
aligendExonsList="${runDir}/alignedExonsList.txt"
aligendIntergenicList="${runDir}/alignedIntergenicList.txt"

exonDepth="${runDir}/alignedExonDepth.txt"
intergenicDepth="${runDir}/alignedIntergenicDepth.txt"

summary="${runDir}/summaryDepthAndIdentity.txt"

: > "${summary}"

### Create lists
# Exon list
awk -F"/" '$NF !~ /^Off/ {print}' "${alignedFilesList}" > "${aligendExonsList}"

# Shuf already exists

# Create intergenic list
awk -F"/" '$NF ~ /^Off/ {print}' "${alignedFilesList}" > "${aligendIntergenicList}"

# Full list already exists


# Find exon depth and identity
if [[ ! -e "${exonDepth}" ]]; then
    declare -a exonicDepthResultFileArray    
    : > "${exonDepth}" # Create or truncate the file

    while read -r filepath; do
        if [[ -e "$filepath" ]]; then
            filename=$(basename "${filepath}" .fa)
            resultFile="${resultDir}/${filename}_result.txt"
            
            # Process in background
            esl-alistat -1 --dna "${filepath}" | sed -n '4p' | awk '{print $4, $10}' > "${resultFile}" &
            exonicDepthResultFileArray+=("${resultFile}")
            # Apply process choke
            pwait "$choketime"
        else
            echo "File $filepath does not exist."
        fi
    done < "${aligendExonsList}"

    # Wait for all background jobs to complete
    wait

    # Compile results
    for each in "${exonicDepthResultFileArray[@]}"; do
        cat "${each}"  >> "${exonDepth}"
        rm "${each}"
    done
fi

# Find len and GC for intergenic
if [[ ! -e "${intergenicDepth}" ]]; then
    declare -a intergenicDepthResultFileArray
    # Create seqsize and C+G content for intergenic
    : > "${intergenicDepth}"

    while read -r filepath; do
        if [[ -e "$filepath" ]]; then
            filename=$(basename "${filepath}" .fa)
            resultFile="${resultDir}/${filename}_result.txt"
            # Process in background
            esl-alistat -1 --dna "${filepath}" | sed -n '4p' | awk '{print $4, $10}' > "${resultFile}" &
            intergenicDepthResultFileArray+=("${resultFile}")

            # Apply process choke
            pwait "$choketime"
        else
            echo "File $filepath does not exist."
        fi
    done < "${aligendIntergenicList}"
    
    # Wait for all background jobs to complete
    wait

    # Compile results
    for each in "${intergenicDepthResultFileArray[@]}"; do
        cat "${each}"  >> "${intergenicDepth}"
        rm "${each}"
    done
fi


# Add summary metrics to a file
exonAndInter=("${exonDepth}" "${intergenicDepth}")
for each in "${exonAndInter[@]}"; do

    filename=$(basename "${each}")

    # Read the file and process each line
    awk -v filename="${filename}" 'BEGIN {
        maxDepth = 0;
        minDepth = 1e9;
    } {

        totalDepth += $1; 
        totalID += $2; 
        sumSqDepth += ($1 * $1); 
        sumSqID += ($2 * $2);
        count++;

        if ($1 > maxDepth) {
            maxDepth = $1;  # Update maxDepth if the current depth is greater
        }
        if ($1 < minDepth) {
            minDepth = $1;  # Update minDepth if the current depth is smaller
        }

    } END {
        meanDepth = totalDepth / count;
        meanID = totalID / count;
        sdDepth = sqrt((sumSqDepth - (totalDepth * totalDepth / count)) / count);
        sdID = sqrt((sumSqID - (totalID * totalID / count)) / count);
        
        printf filename "\n";
        printf "Mean Depth: %f\n", meanDepth;
        printf "Standard Deviation of Depth: %f\n", sdDepth;
        printf "Mean ID: %f\n", meanID;
        printf "Standard Deviation of ID: %f\n", sdID;
        printf "Maximum Depth: %f\n", maxDepth;  # Print maximum depth
        printf "Minimum Depth: %f\n", minDepth;  # Print minimum depth
        printf "\n"
    }' "${each}" >> "${summary}"
done
