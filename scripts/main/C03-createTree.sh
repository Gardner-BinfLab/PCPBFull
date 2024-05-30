#!/bin/bash
# This script creates a single multifasta file for tree building and creates the tree

### HEAD ###

# opening message
echo " "
echo "For creation of multifasta file for tree building and creates the tree"

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

 
function pwait() {
    while [ "$(jobs -p | wc -l)" -ge "$1" ]; do
        sleep 2
    done
}
sleep 0.1

### BODY ###
 
# set vars
alignmentDir="data/alignments/${experiment}/${runName}"
afaFolder="${alignmentDir}/afaAligned"
runDir="data/runs/${experiment}/${runName}"
processedSeqs="${runDir}/${runName}_processedSeqs.txt"
speciesPerAlignment="${runDir}/speciesPerCodingAlignment.txt"
speciesList="speciesLists/${experiment}.txt"
alignmentsHaveAllSpecies="${runDir}/alignmentsHaveAllSpecies.txt"

# run checker
readarray -t processedArray < "${processedSeqs}"
declare -a data_to_write=()

for alignedFile in "${processedArray[@]}"; do 
    filename="${alignedFile}_aligned.fa"
    fullFile="${afaFolder}/${filename}"
    
    if [[ -e "${fullFile}" ]]; then
    lineCount=$(grep -c ">" "${fullFile}")
    data_to_write+=("${fullFile} ${lineCount}")
    fi
done
wait
echo "finished checking, now writing file and checking against species list"

printf "%s\n" "${data_to_write[@]}" > "${speciesPerAlignment}"

#compare this to number of species in specieslist and create list of all afa files that contain all species
speciesListCount=$(wc -l "${speciesList}" | awk '{print $1; exit}')
awk -v speciesCount="${speciesListCount}" '$2 == speciesCount {print $1}' "${speciesPerAlignment}" > "${alignmentsHaveAllSpecies}"

echo "Finished finding all alignments that have all species"
echo "Now making tree"


forTreeMakingFastaFile="${runDir}/${experiment}_forTreeMaking.fa"
treeFile="${runDir}/${experiment}_tree.newick"

# Declare an associative array to hold the species and their corresponding DNA sequences
declare -A speciesArray

# Read the input list file line by line
while read -r filename; do
  # Check if the file exists
  if [[ -f ${filename} ]]; then
    # Using process substitution to avoid creating a subshell for the while loop
    # The output of the awk command is treated as a file, which is read line by line by the while loop
    while read -r line; do
      # If the line starts with '>', it's a species name
      if [[ ${line} =~ ^\> ]]; then
        # Remove the '>' from the start of the line before using it as a key
        key=${line#>}
      else
        # If the line does not start with '>', it's a DNA sequence. Append it to the corresponding species in the array
        speciesArray["${key}"]+="${line}"
      fi
    done < <(awk -v FS="_" '/^>/ {name = ">"$5; for(i=6; i<=NF; i++) name = name"_"$i; print name} !/^>/ {print $0}' "${filename}")
  fi
done < "${alignmentsHaveAllSpecies}"

# Print the species names and their corresponding DNA sequences to the output file
for key in "${!speciesArray[@]}"; do
  echo ">${key}"
  echo "${speciesArray[$key]}" | fold -w 60
done > "${forTreeMakingFastaFile}"

wait

# Create tree file
../software/FastTreeDbl -nt "${forTreeMakingFastaFile}" > "${treeFile}"

echo "tree available at ${treeFile}"
echo "remember to remove bootstrap values (open in figtree and then export should do the trick)"
echo "and then place in the PhyloCSF_Parameters folder"
echo "Also, the newick file cannot use scientific notation, must be decimal"