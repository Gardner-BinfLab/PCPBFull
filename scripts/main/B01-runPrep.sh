#!/usr/bin/bash
# This script is to create a lists of sequences

### HEAD ###

# opening message
echo " "
echo "For creating lists of sequences"

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
read -rp "How many samples would you like to select? " runNum
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

# create 'runNum' sampled exon beds
cat "${bedFolder}/genomicColNoPadPos.bed" "${bedFolder}/genomicColNoPadNegRev.bed" | shuf -n "${runNum}" > "${sampledExonBeds}"

# create exon name list from sampled beds file
awk '{print $1}' "${sampledExonBeds}" > "${sampledExonNames}"

# create sampled offset beds
awk 'NR==FNR{ids[$0]; next} {id=$2"_"$3"_"$4"_"$5; if (id in ids) print}' "${sampledExonNames}" FS="[ _]" "${offsetBeds}" > "${sampledOffsetBeds}"

# create full sample list
cat "${sampledOffsetBeds}" "${sampledExonBeds}" > "${allSampledBeds}"

echo "Done run prep"