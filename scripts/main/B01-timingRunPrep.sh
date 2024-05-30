#!/usr/bin/bash
# This script is to create a lists of sequences, randomly chosen from sizes
# for use in the timing of tools

### HEAD ###

# opening message
echo " "
echo "For preping of running for timing files"

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
echo " "
sleep 0.1

# import config settings
# shellcheck source=/dev/null
source config/main.config.cfg


### BODY ###
#set vars

# Ask how many samples to process and name
read -rp "How many samples would you like to randomly select? " runNum
read -rp "What would you like this run to be called? " runName

# read top line of file (our refSpecies) into array, 
read -r name accession lineage kingdom < "${speciesList}"

# Folder variables
runFolder="data/runs/${experiment_ID}/${runName}"
bedFolder="data/metaData/genomes/${kingdom}/${accession}"

# File variables
offsetBeds="${bedFolder}/genomicOffsets.bed"
sampledExonNames="${runFolder}/${runName}_sampledExonNames.txt"
sampledExonBeds="${runFolder}/${runName}_sampledExonBeds.txt"
sampledOffsetBeds="${runFolder}/${runName}_allsampledOffsetBeds.txt"
allSampledBeds="${runFolder}/${runName}_allSampledBeds.txt"


mkdir -p "${runFolder}"

wait
direction=("Pos" "Neg")

for eachWay in "${direction[@]}"; do

    sortedGenes=${bedFolder}/sortedGenes${eachWay}.bed

    # Calculate the length and sort the file
    if [[ ! -e "${sortedGenes}" ]]; then
        awk '{print $0, $3-$2}' "${bedFolder}/genomicColNoPad${eachWay}.bed" | sort -k5,5n > "${sortedGenes}"
    fi

    # Count the total number of lines
    total_lines=$(wc -l < "${sortedGenes}")

    # Calculate the size of each third
    third_size=$((total_lines / 3))

    # Randomly sample n lines from each third
    top_n=$(head -n $((third_size)) "${sortedGenes}" | shuf -n "${runNum}" | awk '{print $1, $2, $3, $4}')
    middle_n=$(head -n $((third_size * 2)) "${sortedGenes}" | tail -n $((third_size)) | shuf -n "${runNum}" | awk '{print $1, $2, $3, $4}')
    bottom_n=$(tail -n $((third_size)) "${sortedGenes}" | shuf -n "${runNum}" | awk '{print $1, $2, $3, $4}')

    # Combine the sampled lines
    {
        echo "$top_n" 
        echo "$middle_n"
        echo "$bottom_n"
    } >> "${sampledExonBeds}"

done

# create exon name list from sampled beds file
awk '{print $1}' "${sampledExonBeds}" > "${sampledExonNames}"

# create sampled offset beds
awk 'NR==FNR{ids[$0]; next} {id=$2"_"$3"_"$4"_"$5; if (id in ids) print}' "${sampledExonNames}" FS="[ _]" "${offsetBeds}" > "${sampledOffsetBeds}"

# create full sample list
cat "${sampledOffsetBeds}" "${sampledExonBeds}" > "${allSampledBeds}"

echo "Done run prep"