#!/usr/bin/bash

# Deleting all files created by A02

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
source config/main.config.cfg

# variables
nHeadTmp="data/metaData/headers/${headersList}.nheadersList.tmp"

rm "${nHeadTmp}"

# For all species
while IFS= read -r line; do
    read -r name accession lineage kingdom <<< "${line}"
    shortPath="data/metaData/genomes/${kingdom}/${accession}"

    rm "${shortPath}/${accession}.nhead"
done < "${speciesList}"

# For main species only
read -r name accession lineage kingdom < "${speciesList}"
rm -R "data/metaData/genomes/${kingdom}/${accession}"

rm -R "data/mmseqs/${experiment}"