#!/usr/bin/bash
# This script is to take the gff file, convert to bed, and merge overlapping regions
# Then will generate coordinate files for use in esl-sfetch

 
### HEAD ###

# opening message
echo " "
echo "For creation of coordinate files"

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
read -p "Are you running this in a shell with gff2bed tools available? " -n 1 -r
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

### creation of header files ###
# setup
echo "Creating header files"
mkdir -p data/metaData/headers
nHeadTmp="data/metaData/headers/${headersList}.nheadersList.tmp"
nHeadList="data/metaData/headers/${headersList}.nheadersList"

# iterate through files creating headers lists
# Headers lists are details of each sequence stored in the following format
# Sequence ID, species accession number, species name

#check if header exists
if [ -f "${nHeadList}" ]; then
    echo "${headersList}.nheadersList already exists"
else
    if [ -f "${nHeadTmp}" ]; then
        rm "${nHeadTmp}"
    fi

    while IFS= read -r line; do
        read -r name accession lineage kingdom <<< "$line"
        shortPath="data/metaData/genomes/${kingdom}/${accession}"
        genomePath="data/genomes/${kingdom}/${accession}/ncbi_dataset/data/${accession}"
        directFastaFile=$(find "${genomePath}"/ -name "${accession}*.fna")
        nHead="${shortPath}/${accession}.nhead"
        mkdir -p "${shortPath}"

        if [ -f "${nHead}" ];then
            echo "nhead ${nHead} exists"
            cat "${nHead}" >> "${nHeadTmp}"
        else
            echo "found and grabbing headers on ${directFastaFile}"
            grep ^">" "${directFastaFile}" | \
            awk -v cfold="${accession}" -v name="${name}" -F " " 'BEGIN { OFS="," }; { print $1, cfold, name }' | \
            sed -e 's|\./||' -e 's|>||' > "${nHead}"
            cat "${nHead}" >> "${nHeadTmp}"
        fi
    done < "${speciesList}"
    wait
    
    # compiling header files
    echo "Compiling header files"
    LANG=en_EN sort -t , -k 1,1 "${nHeadTmp}" > "${nHeadList}"
    rm "${nHeadTmp}"
fi
### finish of creation of header files ###

#Creation of BED files from GFF
# For main species create BED files
read -r name accession lineage kingdom < "${speciesList}"

shortPath="data/metaData/genomes/${kingdom}/${accession}"
genomePath="data/genomes/${kingdom}/${accession}/ncbi_dataset/data/${accession}"

mkdir -p "${shortPath}"

if [[ ! -f "${shortPath}/genomic.bed" ]]; then
    echo "running command: gff2bed < ${shortPath}/genomic.gff > ${shortPath}/genomic.bed &"
    gff2bed < "${genomePath}/genomic.gff" > "${shortPath}/genomic.bed" &
    pwait "${choketime}"
else
    echo "${accession}/genomic.bed already exists"
fi
echo "making BEDs ..."

# BED Check
wait
echo " "
echo " beds made"
sleep 1

# Creation of CDS only BED from BED
if [[ ! -f "${shortPath}/genomicCDS.bed" ]]; then
    awk -F "\t" '$8=="CDS"' "${shortPath}/genomic.bed" > "${shortPath}/genomicCDS.bed" &
    pwait "${choketime}"
else
    echo "${accession}/genomicCDS.bed already exists"
fi

wait

# Creation of mRNA only BED from BED
if [[ ! -f "${shortPath}/genomic_mRNA.bed" ]]; then
    awk  -F "\t" '$8=="mRNA"' "${shortPath}/genomic.bed" > "${shortPath}/genomic_mRNA.bed" &
    pwait "${choketime}"
else
    echo "${accession}/genomic_mRNA.bed already exists"
fi

# CDS file Check
wait
echo " "
echo " CDS and mRNA only beds made "

# Positive strand CDSs only
if [[ ! -f "${shortPath}/genomicColPos.bed" ]]; then
  echo "running command: bedtools merge -i ${shortPath}/genomicCDS.bed -S + | awk -v rsmal=${removeSmall} -v rlarg=${removeLarge} '\$3-\$2 > rsmal && \$3-\$2 < rlarg {print \$1\"_\"\$2\"_\"\$3, \$2,\$3,\$1}' > ${shortPath}/genomicColNoPadPos.bed &"
  bedtools merge -i "${shortPath}/genomicCDS.bed" -S + | awk -v rsmal="${removeSmall}" -v rlarg="${removeLarge}" '$3-$2 > rsmal && $3-$2 < rlarg {print $1"_"$2"_"$3, $2,$3,$1}' > "${shortPath}/genomicColNoPadPos.bed" &
  pwait "${choketime}"
else
  echo "${accession}/genomicColPos.bed already exists"
fi

# Negative strand CDSs only (Note: order of start and end not reversed until end of script, as needed in this order for rest of script)
if [ ! -f "${shortPath}"/genomicColNeg.bed ]; then
  echo "running command: bedtools merge -i ${shortPath}/genomicCDS.bed -S - | awk -v rsmal=${removeSmall} -v rlarg=${removeLarge} '\$3-\$2 > rsmal && \$3-\$2 < rlarg {print \$1\"_\"\$3\"_\"\$2, \$2,\$3,\$1}' > ${shortPath}/genomicColNoPadNeg.bed &"
  bedtools merge -i "${shortPath}/genomicCDS.bed" -S - | awk -v rsmal="${removeSmall}" -v rlarg="${removeLarge}" '$3-$2 > rsmal && $3-$2 < rlarg {print $1"_"$3"_"$2, $2,$3,$1}' > "${shortPath}/genomicColNoPadNeg.bed" &
  pwait "${choketime}"
else
  echo "${accession}/genomicColNeg.bed already exists"
fi

# Have merged coordinate files finished being made file Check
wait
echo " "
echo " stranded merged files have been made, and have removed sequences under ${removeSmall} and over ${removeLarge} in size"
echo " "
sleep 1

## Genomic length file - Creation of files that show the length of each chromosome/contig for offset finding
if [[ ! -e "${shortPath}/genomicLengths.txt" ]]; then
    echo "creating chromosome length files"

    jq -r '"\(.refseqAccession) \(.length)"' "${genomePath}/sequence_report.jsonl" | sort -k1,1 |awk 'BEGIN {OFS="\t"}{print $1,$2}' > "${shortPath}/genomicLengths.txt"

    wait
    echo " "
    echo "finished creating genomic length files"
fi

# This will create BED files that contain mRNA co-ords, merged with anything less than
# mergeOverlap distance (set in config for this clade). For use in next step
# (Originally created separate positive and negative strand. Will leave these, but probably only need the joint one)

echo " "
echo "making mRNA files with padding for later use"
echo "running bedtools merge -d ${mergeOverlap} -i ${shortPath}/genomic_mRNA.bed > ${shortPath}/mRNApadded.txt <positive and negative strands>"

## bedtools merge -d "${mergeOverlap}" -i "${shortPath}/genomic_mRNA.bed" -S + > "${shortPath}/mRNApaddedPos.txt"
## bedtools merge -d "${mergeOverlap}" -i "${shortPath}/genomic_mRNA.bed" -S - > "${shortPath}/mRNApaddedNeg.txt"
bedtools merge -d "${mergeOverlap}" -i "${shortPath}/genomic_mRNA.bed" > "${shortPath}/mRNApaddedBoth.txt"

# creation of complement BEDs (inverse) of mRNA
# These are the regions with no mRNA annotations
echo " "
echo "creating comlement beds (regions without mRNA annotations)"
echo "running bedtools complement -i ${shortPath}/mRNApaddedBoth.txt -g ${shortPath}/genomicLength.txt > $shortPath/non_mRNABoth.bed"

## bedtools complement -i "${shortPath}/mRNApaddedPos.txt" -g "${shortPath}/genomicLengths.txt" > "${shortPath}/non_mRNAPos.bed"
## bedtools complement -i "${shortPath}/mRNApaddedNeg.txt" -g "${shortPath}/genomicLengths.txt" > "${shortPath}/non_mRNANeg.bed"
bedtools complement -i "${shortPath}/mRNApaddedBoth.txt" -g "${shortPath}/genomicLengths.txt" > "${shortPath}/non_mRNABoth.bed"

wait
echo " "
echo " offset co-ords have been made"

# Create offset files
inFiles=(codingAndNonPos.bed codingAndNonNeg.bed)

# add new IDs and span lengths
awk '{print $1, $2, $3, $4, $3-$2}' "${shortPath}/genomicColNoPadPos.bed" > "${shortPath}/codingPos.txt"
awk '{print $1, $2, $3, $4, $3-$2}' "${shortPath}/genomicColNoPadNeg.bed" > "${shortPath}/codingNeg.txt"
## awk '{print $1"_"$2"_"$3, $2, $3, $1, $3-$2}' "${shortPath}/non_mRNAPos.bed" > "${shortPath}/non_codingPos.txt"
## awk '{print $1"_"$2"_"$3, $2, $3, $1, $3-$2}' "${shortPath}/non_mRNANeg.bed" > "${shortPath}/non_codingNeg.txt"
awk '{print $1"_"$2"_"$3, $2, $3, $1, $3-$2}' "${shortPath}/non_mRNABoth.bed" > "${shortPath}/non_codingBoth.txt"

# Creation of single list of coding and non-coding areas
awk '{print $0, "C"}' "${shortPath}/codingPos.txt" > "${shortPath}/codingAndNonPos.txt"
awk '{print $0, "N"}' "${shortPath}/non_codingBoth.txt" >> "${shortPath}/codingAndNonPos.txt"
sort -k 4,4 -k2,2n "${shortPath}/codingAndNonPos.txt" > "${shortPath}/codingAndNonPos.bed"

awk '{print $0, "C"}' "${shortPath}/codingNeg.txt" > "${shortPath}/codingAndNonNeg.txt"
awk '{print $0, "N"}' "${shortPath}/non_codingBoth.txt" >> "${shortPath}/codingAndNonNeg.txt"
sort -k 4,4 -k2,2n "${shortPath}/codingAndNonNeg.txt" > "${shortPath}/codingAndNonNeg.bed"

wait

for inFile in "${inFiles[@]}"; do
  outFile="${shortPath}/${inFile}".out
  if [[ ! -e "${outFile}" ]]; then
    echo "creating offset files"
    # Awk script to run through the list and create specific non-coding coordinates
    awk '
    BEGIN {OFS="\t"}
    {
        # Store record ids, start, ref, length, and type in separate arrays
        ids[NR] = $1;
        starts[$1] = $2;
        refs[$1] = $4;
        lengths[$1] = $5;
        types[$1] = $6;
    }

    END {
        srand();
        for(i = 1; i <= NR; i++) { 
            # Only consider coding regions
            if(types[ids[i]] == "C") {
                
                # Reset OffPos and OffNeg for the next coding region
                OffPos = "";
                OffNeg = "";

                # Find nearest below non-coding region
                for(j = i - 1; j > 0; j--) {
                    if(types[ids[j]] == "N" && refs[ids[i]] == refs[ids[j]]) {
                        OffNeg = ids[j];
                        break;
                    }
                }

                # Find nearest above non-coding region
                for(j = i + 1; j <= NR; j++) {
                    if(types[ids[j]] == "N" && refs[ids[i]] == refs[ids[j]]) {
                        OffPos = ids[j];
                        break;
                    }
                }

                # Check that we found both above and below regions
                if(OffPos && OffNeg) {
                    # Determine length of coding region
                    len = lengths[ids[i]];

                    # Make sure both non-coding regions are long enough
                    if(lengths[OffPos] >= len && lengths[OffNeg] >= len) {

                        # Calculate random start positions within each non-coding region
                        # that allow for a segment of equal length to the coding region
                        OffPosStart = starts[OffPos] + int(rand() * (lengths[OffPos] - len + 1));
                        OffNegStart = starts[OffNeg] + int(rand() * (lengths[OffNeg] - len + 1));

                        # Output the new record ids with the calculated start and end positions
                        print "OffNeg_" ids[i], OffNegStart, OffNegStart+len, refs[ids[i]]
                        print "OffPos_" ids[i], OffPosStart, OffPosStart+len, refs[ids[i]]
                    }
                }
            }
        }
    }' "${shortPath}/${inFile}" > "${outFile}" &
  else
    echo "${outFile} exists already"
  fi
done
wait

# Split coordinate files for use in esl-sfetch
# Positive strand with offset in non-coding regions in the positive (above) and negative (below) regions
awk '/^OffPos/ { print $1, $2, $3, $4}' "${shortPath}/codingAndNonPos.bed.out" > "${shortPath}/genomicColPosOffPos.bed"
awk '/^OffNeg/ { print $1, $2, $3, $4}' "${shortPath}/codingAndNonPos.bed.out" > "${shortPath}/genomicColPosOffNeg.bed"

# Negative strand with the offset in non-coding regions in the positive (above) and negative (below) regions
awk '/^OffPos/ { print $1, $3, $2, $4}' "${shortPath}/codingAndNonNeg.bed.out" > "${shortPath}/genomicColNegOffPos.bed"
awk '/^OffNeg/ { print $1, $3, $2, $4}' "${shortPath}/codingAndNonNeg.bed.out" > "${shortPath}/genomicColNegOffNeg.bed"

echo "finished awking"


# Offset cleaned file Check
wait
echo " "
echo " offset coordinates have been made"
echo " "
echo "making reverse strand order corrections"

#Reverse the reverse strand order
awk '{print $1, $3, $2, $4}' "${shortPath}/genomicColNoPadNeg.bed" > "${shortPath}/genomicColNoPadNegRev.bed"
wait

# Creation of combined offset bed file
bedOffsets="${shortPath}/genomicOffsets.bed"

cat "${shortPath}/genomicColNegOffNeg.bed" "${shortPath}/genomicColNegOffPos.bed" "${shortPath}/genomicColPosOffNeg.bed" "${shortPath}/genomicColPosOffPos.bed" > "${bedOffsets}"

# Creating mmseqsDB file
# $mmseqsDB and $fnaDB are set in the config file

targetDBFolder="data/mmseqs/${experiment}"

mkdir -p "${targetDBFolder}"

echo "creating target db ${mmseqsDB}"

mmseqs createdb "${fnaDB}" "${mmseqsDB}"

wait
echo " "
echo "created target db"
echo " "

#create target db index
echo "creating target db index"

mmseqs createindex "${mmseqsDB}" "${targetDBFolder}"/tmp

wait
echo "created index"
echo ""

# iterate each species and create indexes for esl-sfetching
echo "creating esl-sfetch indexes"
while IFS= read -r line; do
  read -r name accession lineage kingdom <<< "$line"
  shortPath="data/genomes/${kingdom}/${accession}/ncbi_dataset/data/${accession}"
  fastaFile=$(find "$shortPath"/ -name "${accession}*.fna")

  if [ ! -f "${fastaFile}".ssi ]; then
    echo "running esl-sfetch --index ${fastaFile}"
    esl-sfetch --index "${fastaFile}"
    pwait "${choketime}"
  else
    echo "${fastaFile} index already exists"
  fi
done < "${speciesList}"


echo "finished creating indexing processes"

echo "all done"

