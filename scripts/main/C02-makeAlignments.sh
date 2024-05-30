#!/usr/bin/bash
# This script is to create CLUSTAL format and aligned fasta format files
# it will also create shuffled variants

### HEAD ###

# opening message
echo " "
echo "For creation of alignments and shuffled alignments"

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
read -rp "How many cpus per process do you want? " threads

function pwait() {
    while [ "$(jobs -p | wc -l)" -ge "$1" ]; do
        sleep 5
    done
}
sleep 0.1


### BODY ###
 
### set vars ###

# Alignment data specific
alignmentBase="data/alignments/${experiment}/${runName}"
forAlignmentDir="${alignmentBase}/toBeAligned"
aligned="${alignmentBase}/aligned"
afaAligned="${alignmentBase}/afaAligned"
afaEdited="${alignmentBase}/afaEdited"
shufAligns="${alignmentBase}/shufAligns"

# Run list data specific
runFolder="data/runs/${experiment}/${runName}"
fastaListFileList="${runFolder}/fastaListFileList.txt"
alignedList="${runFolder}/alignedFilesList.txt"
shufAlignedList="${runFolder}/shufAligns.txt"
afaAlignedListFile="${runFolder}/afaAlignedFilesList.txt"
processedList="${runFolder}/${runName}_processedSeqs.txt"
afaEditedListFile="${runFolder}/afaEditedFilesList.txt"
shufAfaAlignedList="${runFolder}/shufAfaAlignedFilesList.txt"
neededOne="${runFolder}/alignmentsNeededOne.txt"
neededTwo="${runFolder}/alignmentsNeededTwo.txt"

# setup
mkdir -p "${aligned}"
mkdir -p "${forAlignmentDir}"
mkdir -p "${afaAligned}"
mkdir -p "${afaEdited}"
mkdir -p "${shufAligns}"
mkdir -p "${runFolder}"
: > "${neededOne}"
: > "${neededTwo}"

### main code run ###

### CLUSTAL alignment creation

echo "making clustal alignments"

sleep 0.1

# setup
: > "${fastaListFileList}"

# Sequence loop. Each line of the file will be a different sequence name.
while read -r sequence; do
    # vars for where sequence names for alignment go
    forAlignmentExons="${forAlignmentDir}/${sequence}.txt"
    forAlignmentOffPos="${forAlignmentDir}/OffPos_${sequence}.txt"
    forAlignmentOffNeg="${forAlignmentDir}/OffNeg_${sequence}.txt"
    # create empty files
    : > "${forAlignmentExons}"
    : > "${forAlignmentOffPos}"
    : > "${forAlignmentOffNeg}"

    # Species loop. Each line of the file will be a different species.
    while read -r name accession lineage kingdom; do
        extractedLoc="data/resultingSeqs/${kingdom}/${accession}"

        # Add each fasta file name to a file for use in clustal alignment
        if [[ -e "${extractedLoc}/Exons/${sequence}_${name}.fa" ]];then
            echo "${extractedLoc}/Exons/${sequence}_${name}.fa" >> "${forAlignmentExons}"
        fi
        if [[ -e "${extractedLoc}/OffPos/OffPos_${sequence}_${name}.fa" ]];then
            echo "${extractedLoc}/OffPos/OffPos_${sequence}_${name}.fa" >> "${forAlignmentOffPos}"
        fi
        if [[ -e "${extractedLoc}/OffNeg/OffNeg_${sequence}_${name}.fa" ]];then
            echo "${extractedLoc}/OffNeg/OffNeg_${sequence}_${name}.fa" >> "${forAlignmentOffNeg}"
        fi
        wait
    done < "${speciesList}"



done < "${processedList}"

wait
# remove empty fasta lists, if they exist
find "${forAlignmentDir}" -type f -empty -delete


# Create list of fasta files lists for use in clustal alignment loop
find "${forAlignmentDir}" -type f > "${fastaListFileList}"
wait

echo " finished creating fasta file lists for use in clustal"

# running of clustalo
readarray -t fastaListArray < "${fastaListFileList}"
declare -a alignmentFileList=()

echo "now running clustalo on fasta files"

for fastaListFile in "${fastaListArray[@]}"; do
    filename=$(basename "${fastaListFile}")
    output_file="${aligned}/${filename%.*}_aligned.clu"
    # Checks if clustal has more than two files to align, if so then align, if not append copies of refSeq then align
    if [[ $(wc -l < "${fastaListFile}") -gt 2 ]]; then

        xargs -a "${fastaListFile}" cat | clustalo --force --threads="${threads}" -i - -o "${output_file}" --outfmt=clu &
        alignmentFileList+=("${output_file}")
        pwait "${choketime}"
    else
        # Read the file into an array
        mapfile -t lines < "${fastaListFile}"

        # Count the number of lines in the array
        num_lines=${#lines[@]}

        # For files with 1 or 2 lines, append lines as needed
        if [[ $num_lines -eq 1 ]]; then
            # File has 1 line; create and append two more copies with unique names in both file and fasta header
            for dupe_num in {1..2}; do
                dupe_file="${lines[0]%.*}_dupe${dupe_num}.fa"
                cp "${lines[0]}" "${dupe_file}"
                # Modify the sequence name within the file for the first line only
                sed -i "1s/^>\([^ ]*\) \(.*\)$/>\\1_dupe${dupe_num} \\2/" "${dupe_file}"
                echo "${dupe_file}" >> "${fastaListFile}" # Append new file path to fastaListFile
            done
            # Also track what files these are
            echo "${filename}" >> "${neededTwo}"
        elif [[ $num_lines -eq 2 ]]; then
            # File has 2 lines; create and append one more copy with a unique name
            dupe_file="${lines[0]%.*}_dupe1.fa"
            cp "${lines[0]}" "${dupe_file}"
            # Modify the sequence name within the file for the first line only
            sed -i "1s/^>\([^ ]*\) \(.*\)$/>\\1_dupe1 \\2/" "${dupe_file}"
            echo "${dupe_file}" >> "${fastaListFile}" # Append new file path to fastaListFile
            # Also track what files these are
            echo "${filename}" >> "${neededOne}"
        fi
        xargs -a "${fastaListFile}" cat | clustalo --force --threads="${threads}" -i - -o "${output_file}" --outfmt=clu &
        alignmentFileList+=("${output_file}")
        pwait "${choketime}"
    fi
done

wait

echo "finished clustalo on fasta files"

#create alignment list file
: > "${alignedList}"
printf "%s\n" "${alignmentFileList[@]}" > "${alignedList}"


### Create shuffled CLUSTAL alignments

echo "shuffle directory set to ${shufAligns}"
echo "finding alignments to shuffle"

#create empty array to store newly shuffled alignment names
declare -a shuf_array=()

#create empty array to store CDS only alignments for shuffling
declare -a alignedCDSarray=()

# finds CDS only sequences
while IFS= read -r line; do
    alignedCDSarray+=("${line}")
done < <(awk -F"/" '$NF !~ /^Off/ {print $0}' "${alignedList}")

echo "shuffling"
for file in "${alignedCDSarray[@]}"; do
    fileName=$(basename "${file}")
    esl-shuffle -A -o "${shufAligns}/Shuf_${fileName}" "${file}" &
    shuf_array+=("${shufAligns}/Shuf_${fileName}")
    pwait "${choketime}"
done
wait
printf "%s\n" "${shuf_array[@]}" > "${shufAlignedList}"
echo "all shuffled"


wait
## Aligned Fasta file creation
echo "Makig fasta aligned files"
sleep 2
# creation of afa files (for software that doesn't like clustalo)
readarray -t clustalAlignments < "${alignedList}"
declare -a afaAlignedList=()
echo "Creating afas"
for alignment in "${clustalAlignments[@]}"; do
    shortFile=$(basename "${alignment}" .clu)
    outputFile="${afaAligned}/${shortFile}.fa"

    esl-reformat --informat clustal -o "${outputFile}" afa "${alignment}" &
    afaAlignedList+=("${outputFile}")
    pwait "${choketime}"
done

#create fasta alignment list file
: > "${afaAlignedListFile}"
printf "%s\n" "${afaAlignedList[@]}" >> "${afaAlignedListFile}"    

wait
echo "finished afas"

# remove "to be aligned" files, as they have now been aligned
# if [[ -d "${forAlignmentDir}" ]]; then
#     rm -r "${forAlignmentDir}"
# fi

### create shuffled alignment fasta format files

# creation of shuffled afa files (for software that doesn't like clustalo)
echo "Creating shuffled afa files"
sleep 2
readarray -t shufClustalAlignments < "${shufAlignedList}"
declare -a afaAlignedList=()
echo "creating shuffled afas"
for alignment in "${shufClustalAlignments[@]}"; do
    shortFile=$(basename "${alignment}" .clu)
    outputFile="${afaAligned}/${shortFile}.fa"

    esl-reformat --informat clustal -o "${outputFile}" afa "${alignment}" &
    afaAlignedList+=("$outputFile")
    pwait "$choketime"
done
wait
#create shuffled fasta alignment list file
printf "%s\n" "${afaAlignedList[@]}" > "${shufAfaAlignedList}"    

wait
echo "finished creating shuffled afas"

### create "clean" afa files - afa alignments with simple species headers
echo " "
echo "creating clean afa files"
sleep 2
declare -a fileNameArray=()
declare -a inputFileArray=()

#create new input file list
while IFS= read -r line; do
    inputFileArray+=("${line}")
done < "${afaAlignedListFile}"

while IFS= read -r line; do
    inputFileArray+=("${line}")
done < "${shufAfaAlignedList}"

: > "${afaEditedListFile}"

for fullFilename in "${inputFileArray[@]}"; do
    filename=$(basename "${fullFilename}")
    newFullFilename="${afaEdited}/${filename}"
    if [[ $filename =~ ^Off ]]; then
        awk 'BEGIN{FS=OFS="_"} /^>/{$1=$2=$3=$4=$5=""; gsub(/^_+|_+$/,""); $0=">"$0} 1' "${fullFilename}" > "${newFullFilename}"
    else
        awk 'BEGIN{FS=OFS="_"} /^>/{$1=$2=$3=$4=""; gsub(/^_+|_+$/,""); $0=">"$0} 1' "${fullFilename}" > "${newFullFilename}"
    fi
    fileNameArray+=("${newFullFilename}")
done

printf "%s\n" "${fileNameArray[@]}" >> "${afaEditedListFile}"

wait
echo "Finished creating clean afa files"
wait

# Extract shuffled ref species sequence
echo "Creating shuffled ref species sequences"
# Result and other
resultingSeqBase="data/resultingSeqs/${refKingdom}/${refAccession}"
types=("Exons" "OffNeg" "OffPos" "Shuf")

mkdir -p "${resultingSeqBase}/Shuf"

# read list of alignments into array
readarray -t shufAlignedListArray < "${shufAlignedList}"

# extracting sequence
for alignedFile in "${shufAlignedListArray[@]}"; do
    filename=$(basename "${alignedFile}" _aligned.clu)
    output_file="${resultingSeqBase}/Shuf/${filename}_${refSpecies}.fa"

    # Prepare to capture the first line of each sequence block
    echo ">${filename}_${refSpecies}" > "${output_file}"
    capture_next_line=false

    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            # An empty line indicates the end of a block, so the next non-empty line should be captured
            capture_next_line=true
        elif $capture_next_line && [[ "$line" =~ $refSpecies ]]; then
            # Extract the sequence part, remove gaps, and write to the output file
            seq="${line##* }"  # Extract the sequence part
            seq="${seq//-/}"   # Remove gaps
            echo "$seq" >> "${output_file}"
            capture_next_line=false  # Reset the flag until the next block
        fi
    done < "${alignedFile}"

done

echo " "
echo "finished extracting all"
wait

# Create single sequences lists
echo " now creating lists"
readarray -t sequenceNamesArray < "${processedList}"

# create lists of sequences per type
for type in "${types[@]}"; do
    declare -a output_array=()
    sequenceFileList="${runFolder}/sequenceFileList_${type}.txt"
    : > "${sequenceFileList}"
    
    if [[ "$type" == "Exons" ]]; then
        for seqFile in "${sequenceNamesArray[@]}"; do
            filename="${seqFile}_${refSpecies}.fa"
            if [[ -e "${resultingSeqBase}/${type}/${filename}" ]]; then
                output_array+=("${resultingSeqBase}/${type}/${filename}")
            fi
        done
    else
        for seqFile in "${sequenceNamesArray[@]}"; do
            filename="${type}_${seqFile}_${refSpecies}.fa"
            if [[ -e "${resultingSeqBase}/${type}/${filename}" ]];then
                output_array+=("${resultingSeqBase}/${type}/${filename}")
            fi
        done
    fi

    printf "%s\n" "${output_array[@]}" > "${sequenceFileList}"

done

echo "finished creating lists"
echo "Script finished"