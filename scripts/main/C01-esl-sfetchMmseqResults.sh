#!/usr/bin/bash
# This script is to create and extract coordinates from mmseq

### HEAD ###

# opening message
echo " "
echo "For create and extract coordinates from mmseq reesults"

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
num_cores="$choketime"

function pwait() {
    while [ "$(jobs -p | wc -l)" -ge "$1" ]; do
        sleep 5
    done
}
sleep 0.1


### BODY ###
 
#set vars
runDir="data/runs/${experiment}/${runName}"
mmseqMatches="results/mmseqs/${experiment}/${runName}/topSpeciesMatches_${runName}_mmseqs"
stagingRunFolder="data/staging/${experiment}/${runName}"
mkdir -p "${stagingRunFolder}"

# tidy up files
awk '!seen[$0]++' "${mmseqMatches}" > "${mmseqMatches}.tmp"
mv "${mmseqMatches}" "${mmseqMatches}".original
mv "${mmseqMatches}.tmp" "${mmseqMatches}"
wait

# split mmseqMatches into individual species groups (this will clober)
echo "making matches files for mmseqs"
awk -F "," -v stagingRunFolder="${stagingRunFolder}" '{print>stagingRunFolder"/"$9"_forCoordMaking.txt"}' "${mmseqMatches}"
wait

# create extraction coords ready for extraction
while read -r name accession lineage kingdom; do
    forCoordMaking="${stagingRunFolder}/${name}_forCoordMaking.txt"
    : > "${stagingRunFolder}/${name}_ExonsCoords.txt"
    : > "${stagingRunFolder}/${name}_OffNegCoords.txt"
    : > "${stagingRunFolder}/${name}_OffPosCoords.txt"

    # checks if values are over the length of the sequence, if so, reduce. Then, checks if values are below 1, if so, changes to 1.
    awk -F, '!/^OffNeg/ && !/^OffPos/ { if ($6 > $8) $6 = $8; if ($7 > $8) $7 = $8; print $1"_"$9,$6,$7,$5}' "${forCoordMaking}" | awk '{if ($2 < 1) $2 = 1; if ($3 < 1) $3 = 1} {print $0}' >> "${stagingRunFolder}/${name}_ExonsCoords.txt"
    awk -F, '/^OffNeg/ { if ($6 > $8) $6 = $8; if ($7 > $8) $7 = $8; print $1"_"$9,$6,$7,$5}' "${forCoordMaking}" | awk '{if ($2 < 1) $2 = 1; if ($3 < 1) $3 = 1} {print $0}' >> "${stagingRunFolder}/${name}_OffNegCoords.txt"
    awk -F, '/^OffPos/ { if ($6 > $8) $6 = $8; if ($7 > $8) $7 = $8; print $1"_"$9,$6,$7,$5}' "${forCoordMaking}" | awk '{if ($2 < 1) $2 = 1; if ($3 < 1) $3 = 1} {print $0}' >> "${stagingRunFolder}/${name}_OffPosCoords.txt"

done < "${speciesList}"
wait
echo "finished creating extraction co ordinates"

# extract sequences
while read -r name accession lineage kingdom; do
    shortPath="data/genomes/${kingdom}/${accession}/ncbi_dataset/data/${accession}"
    fastaFile=$(find "${shortPath}/" -name "${accession}*.fna")
    outPath="data/resultingSeqs/${kingdom}/${accession}"
    placement=(Exons OffNeg OffPos)

    if [[ ! -d "${outPath}" ]]; then
        mkdir -p "${outPath}"
    fi

    for eachPlacement in "${placement[@]}"; do
        coords="${stagingRunFolder}/${name}_${eachPlacement}Coords.txt"
        fastaForExplode="${outPath}/${runName}_genomicForExplode_${eachPlacement}.fna"

        if [[ -f "$coords" ]]; then
            echo "esl-sfetch -Cf ${fastaFile} ${coords} > ${fastaForExplode} &"
            esl-sfetch -Cf "${fastaFile}" "${coords}" > "${fastaForExplode}" &
            pwait "${choketime}"
        fi
    done
  done < "${speciesList}"
wait
echo "finished creating CDS and offset fasta processes"


# explode fastas from one fasta file to individual
shopt -s nullglob
creationList=()
while read -r name accession lineage kingdom; do

    resultingFastaFolder="data/resultingSeqs/${kingdom}/${accession}"
    placement=(Exons OffPos OffNeg)
    tempFolder="${resultingFastaFolder}/temp"
    outPath="data/resultingSeqs/${kingdom}/${accession}"
    mkdir -p "${resultingFastaFolder}"/{Exons,OffPos,OffNeg,completed}
    mkdir -p "${tempFolder}"/{Exons,OffPos,OffNeg}

    # explode fastas
    for eachPlacement in "${placement[@]}"; do
        fastaForExplode="${outPath}/${runName}_genomicForExplode_${eachPlacement}.fna"
        if [[ -e "${fastaForExplode}" ]]; then
            fastaexplode "${fastaForExplode}" -d "${tempFolder}/${eachPlacement}/" &
        fi
    done
    echo "Exploding fastas. . . grab a coffee . . . will take quite a while (like... 5 mins?)"
    wait
    
    # Move temp files to useful location and tidy up multifastas
    for eachPlacement in "${placement[@]}"; do
        fastaForExplode="${outPath}/${runName}_genomicForExplode_${eachPlacement}.fna"
        mv "${fastaForExplode}" "${outPath}/completed/"
        for file in "${tempFolder}/${eachPlacement}"/*; do
            base=$(basename "${file}")
            mv "${file}" "${resultingFastaFolder}/${eachPlacement}/"
            echo "Created ${resultingFastaFolder}/${eachPlacement}/${base}"
            creationList+=("${resultingFastaFolder}/${eachPlacement}/${base}")
        done
    done
    wait
    rm -r "${tempFolder}"

done < "${speciesList}"
wait
printf "%s\n" "${creationList[@]}" > "${runDir}/${runName}_createdFastaFiles.txt"

echo "Done"