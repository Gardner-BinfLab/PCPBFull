This is the repository for the protein coding potential calculator benchmark paper pipeline, data and results.
For use on Linux.


#########################

Simple Access Instructions

#########################

To access the project, create a local project directory. For example:
```
mkdir PCPCBenchmark
```
Clone this repository to the project directory.
```
git clone https://github.com/fienx/coding-potential-comparison PCPCBenchmark
```

This will download the benchmarking pipline and curated paper data and results.
The data and results pertaining to the paper are located in the paperData directory.

If you want to use any of the scripts, you will need to perform further installation steps.


#########################

Dependencies

#########################

A lot of dependencies have been set in the conda environemnt YML file.

Create a new conda environment using the YML file loated in the scripts directory.
```
conda env create -f scripts/support/condaEnv.yml
```

Some software was unavailable for adding to the conda environment and will need to be installed manually. These are:
<insert list>


#######

Pipeline Purpose

#######

This pipeline has been created for the purpose of benchmarking specific protein coding potential calculators. For the research paper that is relevant to this pipeline, please see: <insert link>

This pipeline can also be used to create test datasets of your own genomic choosing and to run your own benchmarks of protein coding potential calculators.



#######

How to use this pipeline

#######

When running a script, always run from the project directory, unless otherwise specified e.g. 
```
scripts/main/D01-runRNAcode.sh
```

Start with the scripts in alphabetical and numerical order.

"Now remember to make a species list(s) and place in: speciesLists/<cladeName>.txt
that follows this format:

name    assescion    lineage     kingdom
E.g.

Felis_catus     GCF_018350175.1 carnivora_odb10         animalia
Panthera_tigris GCF_018350195.1 carnivora_odb10         animalia
Mustel_erminea  GCF_009829155.1 carnivora_odb10         animalia
Equus_caballus  GCF_002863925.1 laurasiatheria_odb10    animalia

Also create a config for this clade and place in: config/config_<cladeName>.cfg
E.g. :

# Reference species name
refSpecies=Felis_catus

# Name of clade (also known as experiment group)
experiment=catGroup

# These don't need to be touched
speciesList=speciesLists/\${experiment}.txt
fnaDB=data/databases/\${experiment}.fna
nhmmerDB=data/databases/\${experiment}.db
mmseqsDB=data/mmseqs/\${experiment}/\${experiment}_targetDB.mmseqs
headersList=\${experiment}

# Creation of merged overlaping CDS coordinate files (creates
# intergenic regions that are greater than 1kb)
mergeOverlap=1000

# removes very large and small sequences that are 'n' nucleotides in length
removeSmall=80
removeLarge=1200

# Pads this many nucleotides before and after (extends the the length of sequence extracted)
pad=75
"


#######

Brief Description of scripts

#######

The "A" scripts are for downloading of genomes and calculation and creation of the corresponding data needed for sequence extraction.

The "B" scripts are for creation of "runs" - creation of lists of sampled sequences and searching for homologues.

The "C" scripts are for extraction of sequences from genomes and creation of alignments. Also, pre tool benchmark checks.

The "D" scripts are for the benchmarking of the tools.

The "R" 'R' scripts are for interpreting the results of the benchmarking using 'R'.

The "T" scripts are for benchmarking timing of software.



######################

Specifics of scripts

######################

A01-downloadGenomes
Configuration Import - begins by importing global configurations and experiment-specific settings from external configuration files.
Reading Species List - A list of species, along with their accession numbers, lineages, and kingdoms, is read from a file into an array.
Genome Download - iterates over each species in the list and downloads the respective genomes from the NCBI database using the datasets program. The downloaded files include GFF3, genomic sequences, and sequence reports.
Genome Extraction - After downloading, unzips each genome package.
Database Creation - The user is prompted to create a combined FASTA database. If agreed, concatenates all downloaded genomic sequences into a single FASTA file.

A02-createMergedBeds
Header File Creation - initiates the process by creating header files that store details about each sequence, including the Sequence ID, species accession number, and species name. These header files are used for downstream analyses.
BED File Creation - converts GFF files to BED format, specifying genomic regions for each species.
BED File Subsetting - Separate BED files for coding (CDS) and mRNA regions are created for further analysis.
Merged BED Files - generates merged BED files that include both coding and non-coding regions.
Genomic Length File Creation - A file containing the length of each chromosome or contig is created for each species.
Non-coding Region Identification - calculates non-coding regions as the complement of the mRNA regions. These are stored in separate BED files for positive and negative strands.
Offset Coordinate Calculation - calculates offset coordinates for each coding region, based on its nearest non-coding region longer than 1k. These offsets are stored in new BED files.
Database and Index Creation - creates a database using MMseqs2 and generates an index for the database.
ESL-Sfetch Indexing - Finally, creates indexes for each species' genome using esl-sfetch.

###
B01-runPrep
User Input for Sampling Parameters - The script starts by asking the user to input the number of samples they want to randomly select and what they would like to name this run.
Creation of Sampled Exon Beds - The script randomly samples 'n' exons (as specified by the user) from the merged BED files containing both positive and reverse strands. These sampled exon BED files are saved for further analysis.
Generation of Sampled Exon Names - The script extracts the names of the sampled exons from the BED files and saves them in a separate file. This is done to facilitate the creation of corresponding sampled offset BED files.
Creation of Sampled Offset Beds - The script then creates BED files containing the sampled offsets. These are identified by matching the exon names from the sampled exons to the previously generated offset BED files.
Compilation of All Sampled BEDs - Finally, the script concatenates the sampled exon and offset BED files to create a comprehensive list of all sampled BEDs. This will be used for the sequence extraction process.

B02-cleanNegatives



B03-runMmseq
Database and Query Preparation - The script starts by checking if the target MMSEQS2 database exists. If not, it terminates the script. It also checks if the query database exists; if not, it builds it using esl-sfetch and mmseqs.
MMSEQS2 Search - The MMSEQS2 search is run with specified parameters, including the number of threads to use and the search type. The results are saved in the MMSEQS database format.
Result Interpretation - The MMSEQS2 results are converted into a more human-readable tab-delimited format. This is done using the convertalis command of MMSEQS2 with specified output fields.
Result Compilation - The script does additional processing to compile the results. It adds species information, filters out duplicates based on query and species, and extends the coordinates based on the pad value set in the config file. The results are saved in a CSV format for further analysis.
Final Filtering and List Preparation - Finally, the script filters out sequences based on the number of exon matches. Only those sequences with one or more exon matches are retained.


C01-esl-sfetchMmseqResults
Data Preparation and File Cleanup - Your script starts by loading run files and setting up directories for both the MMSEQS matches and the staged data. You then de-duplicate the MMSEQS matches file to ensure that each match appears only once.
Grouping by Species  You use AWK to split the MMSEQS matches into individual files based on the species. This makes it easier to work with data for each species separately later in the script.
Coordinate Creation - For each species, you create three coordinate files (ExonsCoords.txt, OffNegCoords.txt, OffPosCoords.txt). These files contain the coordinates for sequence extraction. You also ensure that the coordinates are within the sequence length and greater than 0.
Sequence Extraction - You then use esl-sfetch to fetch sequences based on these coordinates. You perform this operation for each of the three types of coordinates (exons, offsets in the negative direction, and offsets in the positive direction).
Sequence File Splitting - Lastly, you use fastaexplode to split the multifasta files into individual fasta files. These files are moved to their respective directories, and a list of created files is saved.


C02-makeAlignments
Creating CLUSTAL Alignments
Sequence Loop: For each sequence, identify the extracted sequences for Exons, OffPos, and OffNeg across all species. Save these in text files.
Species Loop: Fill the above text files with paths to the actual sequence files.
Running ClustalO: Create alignments using ClustalO. Handle the case where the number of sequences is less than 3 by appending additional lines.
Creating Shuffled CLUSTAL Alignments - Use esl-shuffle to shuffle the alignments, focusing on CDS-only sequences.
Converting to Aligned Fasta Format - Convert the CLUSTAL alignments to aligned FASTA (AFA) format using esl-reformat.
Cleaning AFA Files - Clean the AFA files to have simpler headers, making the data compatible with other software.
Extracting Reference Species Sequences from Shuffled Alignments - Extract the shuffled sequences of the reference species from the shuffled alignments.
Creating Sequence Lists - Create lists of sequences for each type (Exons, OffNeg, OffPos, Shuf).









Details of scripts below (OUT OF DATE, currently updating)
#############################################
A01-downloadGenomes
Summary:
Takes a file list of species specified in the experiment configuration file and downloads their genomic data from ncbi.
e.g. melonGroup.txt or catGroup.txt etc
The file list contains on each line one species with data from "NCBI RefSeq assembly" in this order:
name accession BUSCO_lineage_group kingdom
e.g.
Cucumis_melo    GCF_025177605.1 eudicots_odb10  plantae

Details:
Reads file into array.
Loops through each species.
uses ncbi tool "datasets" to download each species associated files into the data folder.
Unzips each species.
Creates fasta database file, with fake DNA data as the first sequence to make sure any tools see the database as a DNA file (sometimes some tools have issues with telemeric data that is often at the top of the first sequence.


(note to self: simplify this description and rearrange with most important thing first)
(mappin of sequence ids to species ids
bed files of coding to sample from
bed files of intergenic to sample from)

###########################################
A02-createMergedBeds
Summary:
Creates list of sequence headers and combines them with their accession numbers and species name from each fasta file from each species listed in the experiment configuration file. Each line in this headers list is formatted as:
sequenceName, accession, species
And is then sorted by alphabeticall order of the sequence name

Create bed files that contain coordinates for CDS extraction (positive control) and non-mRNA extraction (negative control)

Details:
Checks if headers list exists and if not, creates it

For only the ref species in the experiment configuration:
    Converts gff file to bed
    Extracts from bed, and creates a new file with CDS coordinates
    Extracts from bed, and creates a new file with mRNA coordinates
    Merges any CDS overlap regions and creates stranded coordinate files
    Creates file with chromosome lengths
    Creates padded, merged and stranded mRNA files
    Creates inverse of the padded, merged and stranded mRNA files
    Creates succinct bed files for use in esl-sfetch of CDS and non-mRNA files (i.e. intergenic regions)
    Joins these CDS and non-mRNA files for use in offset coordinate finding
    For each CDS sequence, calculate offset coordinates that are of the same length from the nearest non-mRNA regions above and below the CDS sequence.
    Split these sequences into files based on strand and offset type


###########################################
A03-esl-sfetch
Summary:
Create grouped fasta files of CDS and non-mRNA sequences

Details: For each species in species list, checks if the esl-sfetch index file exists, and creates if not

For only the ref species:
    use esl-sfetch to extract CDS sequences
    use esl-sfetch to extract non-mRNA offset sequences


###############################################
A04-fastaExplode
Summary:
Splits fasta files created by esl-sfetch
Details:
For each species, split the CDSs, and intergenic offset fasta sequences derived from a03. Also, will split any fasta files created by a07


##############################################
A05-createMmseqsDB
Summary:
Creates target mmseqs database
Details:
Creates a target mmseqs database based on the joined fasta file DB for the experiment


##############################################
A06-randomlyRunMmseq
Summary:
Runs mmseq on a set number of randomly selected sequences, also adds padding to homologous regions
Details:
For ref species:
    Set number of random sequences to run (MOVE THIS TO MUCH EARLIER (to avoid exorbitant number of fasta files))
    Creates query database for mmseqs
    runs mmseq on query and target DBs
    Converts results output, resports only top hit per genome
    Pads ref query results (extends start and end coordinates by set amount, CONFIG)
    Pads all query results (extends start and end coordinates to same as ref query)

A07-esl-sfetch-from-mmseq-results
Summary:
Create grouped fasta files of results from mmseqs
Details:
