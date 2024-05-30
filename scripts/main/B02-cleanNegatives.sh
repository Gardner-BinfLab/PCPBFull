#!/usr/bin/bash
# This script is to check if the intergenic ("Off") negative controls
# do not have any hits to translated protiens from a protien DB


### HEAD ###

# opening message
echo " "
echo "To check the negative controls are negative (remove obvious protein coding sequences)"

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

 
# Cores to use
read -rp "How many cores would you like to use? " threads

sleep 0.1

# Cutoff values
read -rp "What e-value cutoff? (Suggested range: 1E-30 to 1E-06 Default: 1E-10)" evalue
evalue=${evalue:-1E-10}
read -rp "What bitscore cutoff? (Suggested range: 25 to 40) Default: 31" bitscore
bitscore=${bitscore:-31}

### BODY ###

# Load run files
runName=$(bash scripts/support/toolGetRuns.sh "$experiment_ID") 
echo "Loading run. . . "

# read top line of file (our refSpecies) into array, 
read -r name accession lineage kingdom < "${speciesList}"

# Folder variables
runFolder="data/runs/${experiment_ID}/${runName}"
genomePath="data/genomes/${kingdom}/${accession}/ncbi_dataset/data/${accession}"
queryDBFolder="data/mmseqsProtein/${experiment_ID}/${runName}"
resultsFolder="results/mmseqsProtein/${experiment_ID}/${runName}"
targetDbFolder="data/mmseqsProtein/${experiment_ID}"

mkdir -p "${resultsFolder}"
mkdir -p "${queryDBFolder}"

# File variables
targetFasta=$(find data/protein/"${experiment_ID}" -name "*.fasta")
targetDB="${targetDbFolder}/${experiment_ID}_protein_targetDB.mmseqs"
sampledOffsetBeds="${runFolder}/${runName}_allsampledOffsetBeds.txt"
fastaFile=$(find "${genomePath}"/ -name "${accession}*.fna")
queryDB="${queryDBFolder}/${runName}_offset_queryDB.mmseqs"
resultsDB="${resultsFolder}/${runName}_offset_resultsDB.mmseqs"
resultsConverted="${resultsFolder}/${runName}_offset_result_mmseqs.m8"
allSampledBeds="${runFolder}/${runName}_allSampledBeds.txt"
allSampledBedsFilt="${runFolder}/${runName}_allSampledBedsFilt.txt"

# Check if protein fasta file has been downloaded
if [[ ! -e "${targetFasta}" ]]; then
    echo "Please download the reference genomes protein db from Uniprot"
    echo "and place in data/protein/${experiment_ID}"
    echo "then try again"
    exit 1
fi

# Check query database has been built, if not, build it
if [[ ! -e "${queryDB}" ]]; then
    esl-sfetch -Cf "${fastaFile}" "${sampledOffsetBeds}" | mmseqs createdb stdin "${queryDB}"
fi
wait

# Create target mmseqs DB
if [[ ! -e "${targetDB}" ]]; then
    mmseqs createdb "${targetFasta[0]}" "${targetDB}"
fi
wait

# running mmseqs
mmseqs search --threads "${threads}" -e 5 --mask 0 -s 7 "${queryDB}" "${targetDB}" "${resultsDB}" "${resultsFolder}/tmp"
wait

# convert results
mmseqs convertalis "${queryDB}" "${targetDB}" "${resultsDB}" "${resultsConverted}" --format-output "query,target,fident,tlen,mismatch,gapopen,qstart,qend,tstart,tend,evalue,bits,empty,qlen" 
wait

# Create new allSampledBeds text file without protein intergenic details
sort -k11g,11 "${resultsConverted}" | \
awk '!seen[$1]++' | \
awk 'function abs(v) {v += 0; return v < 0 ? -v : v}; \
     {print $1, abs($10-$9), $11, $3}' | \
awk -v evalue="${evalue}" -v bitscore="${bitscore}" '{if($2 > bitscore && $3 < evalue) print $1}' | \
awk -F"_" 'BEGIN {OFS = "_"}{print $2,$3,$4,$5}' | \
grep -v -f - "${allSampledBeds}" > "${allSampledBedsFilt}"