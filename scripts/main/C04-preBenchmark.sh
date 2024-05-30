#!/bin/bash

# Creates a file of nucleotide sizes and GC content for use in timing and summary

# opening message
echo " "
echo "For creating nucleotide size and GC data file"

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
resultDir="results/infoseq/${experiment}/${runName}"
mkdir -p "${resultDir}"

# Var
fullSequenceFileList="${runDir}/fullSequenceFileList.txt"

exonList="${runDir}/sequenceFileList_Exons.txt"
intergenicPosList="${runDir}/sequenceFileList_OffPos.txt"
intergenicNegList="${runDir}/sequenceFileList_OffNeg.txt"
intergenicList="${runDir}/sequenceFileList_Intergenic.txt"
shufList="${runDir}/sequenceFileList_Shuf.txt"

validExonFilesList="${runDir}/validExonFilesList.txt"
validIntergenicFilesList="${runDir}/validIntergenicFilesList.txt"
validShufFilesList="${runDir}/validShufFilesList.txt"

validSequenceFilesList="${runDir}/validSequenceFilesList.txt"

seqSizes="${runDir}/sequenceSizes.txt"
intergenicSeqSizes="${runDir}/intergenicSizes.txt"

summary="${runDir}/summaryLenAndGC.txt"

: > "${fullSequenceFileList}"
: > "${intergenicList}"
: > "${summary}"

### Create lists
# Exon already exits
# Intergenic Pos and neg already exist
# Shuf already exists

# Create intergenic list
cat "${intergenicPosList}" > "${intergenicList}"
cat "${intergenicNegList}" >> "${intergenicList}"

# Create full file list
types=("Exons" "OffNeg" "OffPos" "Shuf")
for type in "${types[@]}"; do
    cat "${runDir}/sequenceFileList_${type}.txt" >> "${fullSequenceFileList}"
done

### Create validated lists
# Create validated exon file list
: > "${validExonFilesList}"
while read -r filepath; do 
    if [[ -e "$filepath" ]]; then
        echo "$filepath" >> "${validExonFilesList}"
    fi
done < "${exonList}"

# Create validated intergentic file list
: > "${validIntergenicFilesList}"
while read -r filepath; do 
    if [[ -e "$filepath" ]]; then
        echo "$filepath" >> "${validIntergenicFilesList}"
    fi
done < "${intergenicList}"

# Create validated shuffled file list
: > "${validShufFilesList}"
while read -r filepath; do 
    if [[ -e "$filepath" ]]; then
        echo "$filepath" >> "${validShufFilesList}"
    fi
done < "${shufList}"

# Create validated full file list
: > "${validSequenceFilesList}"
{
    cat "${validExonFilesList}" 
    cat "${validIntergenicFilesList}"
    cat "${validShufFilesList}"
} >> "${validSequenceFilesList}"


# Find len and GC for exons
declare -a exonicInfoseqResultFileArray    
: > "${seqSizes}" # Create or truncate the file


while read -r filepath; do
    if [[ -e "$filepath" ]]; then
        filename=$(basename "${filepath}" .fa)
        resultFile="${resultDir}/${filename}_result.txt"
        
        # Process in background
        infoseq -auto -only -name -length -pgc "${filepath}" | awk 'NR==2' | sed -e 's/_[^_ ]*_[^_ ]* / /' -e 's/[[:space:]]*$//' -re 's/[[:space:]]+/,/g' > "${resultFile}" &
        exonicInfoseqResultFileArray+=("${resultFile}")
        # Apply process choke
        pwait "$choketime"
    else
        echo "File $filepath does not exist."
    fi
done < "${validExonFilesList}"

# Wait for all background jobs to complete
wait

# Compile results
for each in "${exonicInfoseqResultFileArray[@]}"; do
    cat "${each}"  >> "${seqSizes}"
    rm "${each}"
done

# Copy seqSizes to pertinent locale
seqSizesFile=$(basename "${seqSizes}" .txt)
cp "${seqSizes}" "${compiledResultsFolder}/${experiment}_${runName}_${seqSizesFile}.csv"

# Find len and GC for intergenic
declare -a intergenicInfoseqResultFileArray
# Create seqsize and C+G content for intergenic
: > "${intergenicSeqSizes}"

while read -r filepath; do
    if [[ -e "$filepath" ]]; then
        filename=$(basename "${filepath}" .fa)
        resultFile="${resultDir}/${filename}_result.txt"
        # Process in background
        infoseq -auto -only -name -length -pgc "${filepath}" | awk 'NR==2' | sed -e 's/_[^_ ]*_[^_ ]* / /' -e 's/[[:space:]]*$//' -re 's/[[:space:]]+/,/g' > "${resultFile}" &
        intergenicInfoseqResultFileArray+=("${resultFile}")

        # Apply process choke
        pwait "$choketime"
    else
        echo "File $filepath does not exist."
    fi
done < "${validIntergenicFilesList}"

# Wait for all background jobs to complete
wait

# Compile results
for each in "${intergenicInfoseqResultFileArray[@]}"; do
    cat "${each}"  >> "${intergenicSeqSizes}"
    rm "${each}"
done


# Add summary metrics to a file
exonAndInter=("${seqSizes}" "${intergenicSeqSizes}")
for each in "${exonAndInter[@]}"; do

    filename=$(basename "${each}")

    # Read the file and process each line
    awk -F"," -v filename="${filename}" '{

        totalLength += $2; 
        totalGC += $3; 
        sumSqLength += ($2 * $2); 
        sumSqGC += ($3 * $3);
        count++;
    } END {
        meanLength = totalLength / count;
        meanGC = totalGC / count;
        sdLength = sqrt((sumSqLength - (totalLength * totalLength / count)) / count);
        sdGC = sqrt((sumSqGC - (totalGC * totalGC / count)) / count);
        
        printf filename "\n";
        printf "Mean Length: %f\n", meanLength;
        printf "Standard Deviation of Length: %f\n", sdLength;
        printf "Mean GC Content: %f\n", meanGC;
        printf "Standard Deviation of GC Content: %f\n", sdGC;
        printf "\n"
    }' "${each}" >> "${summary}"
done
