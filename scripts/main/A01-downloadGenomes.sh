#!/usr/bin/bash
# This script is to download, unzip genomes from NCBI


### HEAD ###

# opening message
echo " "
echo "For download and unziping of genomes from NCBI"

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
read -p "Are you running this in a shell with ncbi_dataset tools available? " -n 1 -r
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
        sleep 5
    done
}
sleep 0.1

### BODY ###

# read file of species into array
readarray -t fileList < "${speciesList}"

# iterate each line and download file from ncbi using datasets program
for eachLine in "${fileList[@]}"; do
  read -r name accession lineage kingdom <<< "${eachLine}"
  shortPath="data/genomes/${kingdom}/${accession}"

  if [[ ! -e "${shortPath}/${accession}".zip ]]; then
    mkdir -p "${shortPath}"
    echo "running command: datasets download genome accession ${accession} --include gff3,rna,cds,protein,genome,seq-report --filename ${shortPath}/${accession}.zip &"
    datasets download genome accession "${accession}" --include gff3,genome,seq-report --filename "${shortPath}/${accession}".zip &
    pwait "${choketime}"
  else
    echo "${accession} already exists"
  fi

done

echo "downloading ..."
wait

echo "Finished downloading"
echo " "
echo "Extracting. . ."

sleep 1

# Unzip sequences
for eachLine in "${fileList[@]}"; do
  read -r name accession lineage kingdom <<< "${eachLine}"
  shortPath="data/genomes/${kingdom}/${accession}"

  if [[ ! -d "$shortPath"/ncbi_dataset ]]; then
  echo "extracting ${shortPath}/${accession}.zip"
    unzip -d "${shortPath}" "${shortPath}/${accession}.zip" &
    pwait "${choketime}"
  else
    echo "${accession} already extracted"
  fi

done

wait
echo "finished extracting"
sleep 2

# Creating database
read -p "Do you wish to create a combined fasta database file? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting"
    echo " "
    exit 1
fi
sleep 0.1

mkdir -p data/databases

# add fake data for first sequence. Helps with detection algos in many programs, since sometimes first seq can be shit
cat data/genomes/FakeDNA.fna > "data/databases/${experiment}.fna"

for eachLine in "${fileList[@]}"; do
  read -r name accession lineage kingdom <<< "${eachLine}"
  shortPath="data/genomes/${kingdom}/${accession}"
  echo "adding ${name}"
  cat "${shortPath}/ncbi_dataset/data/${accession}/${accession}"*genomic.fna >> "data/databases/${experiment}.fna"
done
wait
echo "Finished database building: data/databases/${experiment}.fna"
