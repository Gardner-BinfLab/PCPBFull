#!/usr/bin/bash
# This script is to randomly select an amount of fasta files.
# This will also grab the coresponding files from the offset pos and neg fastas
# And will then run mmseqs2


### HEAD ###

# opening message
echo " "
echo "For to randomly select an amount of fasta files and run mmseqs2"

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
read -rp "Maximum ram (in GB) to use? (Leave 20% extra for overhead)" memLimit 

sleep 0.1


### BODY ###

# Load run files
runName=$(bash scripts/support/toolGetRuns.sh "$experiment_ID") 
echo "Loading run. . . "

# read top line of file (our refSpecies) into array, 
read -r name accession lineage kingdom < "${speciesList}"

# Folder variables
runFolder="data/runs/${experiment_ID}/${runName}"
genomePath="data/genomes/${kingdom}/${accession}/ncbi_dataset/data/${accession}"
queryDBFolder="data/mmseqs/${experiment}/${runName}"
resultsFolder="results/mmseqs/${experiment_ID}/${runName}"

# File variables
fastaFile=$(find "${genomePath}"/ -name "${accession}*.fna")
allSampledBedsFilt="${runFolder}/${runName}_allSampledBedsFilt.txt"
targetDB="${mmseqsDB}"
queryDB="${queryDBFolder}/${runName}_queryDB.mmseqs"
resultsDB="${resultsFolder}/${runName}_resultsDB.mmseqs"
resultsConverted="${resultsFolder}/${runName}_mmseqs.m8"
nHeadList="data/metaData/headers/${headersList}.nheadersList"
nHeadListTab="data/metaData/headers/${headersList}TabSep.nheadersList"
compiledResults="${resultsFolder}/${runName}_mmseqs.compiled"

mkdir -p "${resultsFolder}"
mkdir -p "${queryDBFolder}"

wait

# check target database exists
if [[ -f "${targetDB}" ]]; then
    echo "using database: ${targetDB}"
else
    echo "no target database found at ${targetDB}, please run create mmseqs target database script"
    exit 0
fi

# Check query database has been built, if not, build it
if [[ ! -e "${queryDB}" ]]; then
    esl-sfetch -Cf "${fastaFile}" "${allSampledBedsFilt}" | mmseqs createdb stdin "${queryDB}"
fi

wait
echo "query database has been created"
echo " "
echo "now running mmseqs on ${targetDB} and ${queryDB}"
echo " "

# running mmseqs
mmseqs search --split-memory-limit "${memLimit}"G --threads "${threads}" -e 5 --mask 0 -s 7 --search-type 3 "${queryDB}" "${targetDB}" "${resultsDB}" "${resultsFolder}/tmp"

wait

echo " "
echo "mmseqs has finished running. Now interpreting results"
echo " "
wait

# converting mmseq results
echo " "
echo "now interpreting results"
if [[ -e "${resultsConverted}" ]]; then
    echo "run results already interpreted for ${runName}"
    exit 0
fi

mmseqs convertalis "${queryDB}" "${targetDB}" "${resultsDB}" "${resultsConverted}" --format-output "query,target,fident,tlen,mismatch,gapopen,qstart,qend,tstart,tend,evalue,bits,empty,qlen"

wait
echo " "
echo "results interpreted successfully"
echo " "
echo "now compiling results"

# compiling mmseq results
# make sure tab separated headers list exists
if [[ ! -e "${nHeadListTab}" ]]; then
    awk 'BEGIN{FS=",";OFS="\t"}{print $1,$2,$3}' "${nHeadList}" > "${nHeadListTab}"
fi
wait

# maps fields for unique search and prints top hits
#awk -F'\t' 'BEGIN {OFS = "\t"} NR==FNR {map[$1]=$3; next} {print $0, map[$2]}' "$nHeadListTab" "$resultsConverted" | awk '!seen[$1 FS $13]++' FS='\t' > "$compiledResults"
awk -F'\t' 'BEGIN {OFS = "\t"} NR==FNR {map[$1]=$3; next} { $13 = map[$2]; if (!seen[$1 FS $13]++) print }' "${nHeadListTab}" "${resultsConverted}" > "${compiledResults}.step2"

wait

# extend results to be similar length to refspecies query, pad a bit extra (pad var set in config), and swap start and end if on reverse strand
awk -v pad=${pad} -v OFS='\t' '{
    if ($7 < $8) { 
        $9 = ($9 - ($7 - 1)) - pad; 
        $10 = ($10 + ($14 - $8)) + pad; 
    } 
    else { 
        temp9 = $9; 
        $9 = ($10 + ($8 - 1)) + pad; 
        $10 = (temp9 - ($14 - $7)) - pad;
    } 
    print 
}' "${compiledResults}.step2" > "${compiledResults}"
wait

# prep file the same as for nhmmer results
# checks that start values are not 0 or negative and that end values are not larger than 
awk -v OFS=',' '($7 > 0 && $8 > 0 && $4 > $10) { print $1, $11, $12, $5, $2, $9, $10, $4, $13 }' "${compiledResults}" > "${resultsFolder}/topSpeciesMatches_${runName}_mmseqs"
wait


# prep file for use in esl-sfetch. Only use sequences that contain 1 or more exon match
processedList="data/runs/${experiment}/${runName}/${runName}_processedSeqs.txt"

awk -F',' '!($1 ~ /^Off/) {print $1}' "${resultsFolder}/topSpeciesMatches_${runName}_mmseqs" | sort | uniq -c | awk '$1>=1{print $2}' > "${processedList}"

wait
echo " done"
echo " "