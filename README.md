# Protein Calculator Potential Benchmark

This is the repository for a software pipeline to reproduce results in the paper 'Flawed machine-learning confounds coding sequence annotation' - https://doi.org/10.1101/2024.05.16.594598
If you are wanting the results, sequences, or alignments used in the paper, please see https://github.com/Gardner-BinfLab/PCPBSlim

Due to the random sampling, results may differ slightly to those in the paper.
For use on Linux.


## Simple Access Instructions

To access the project, create a local project directory. For example:
```
mkdir PCPBFull
```
Clone this repository to the project directory.
```
git clone https://github.com/Gardner-BinfLab/PCPBFull PCPCFull
```

This will download the benchmarking pipline.


## Dependencies

A lot of dependencies have already been set in the conda environemnt YML file.

First, you will need to download and install conda if you do not already have it. See here: https://docs.anaconda.com/free/miniconda/miniconda-install/

Next, create a new conda environment using the YML file loated in the scripts directory.
```
conda env create -f scripts/support/pcpc.yml
```

Some software was unavailable for adding to the conda environment and will need to be installed manually. These are:
rnasamba (could not solve, and had to be installed in a separate conda environment)


## How to use this pipeline

When running a script, always run from the project base directory. 
e.g.
```
scripts/main/A00-initialise.sh
```

Start with the scripts in alphabetical and numerical order.


## Brief Description of scripts

The "A" scripts are for downloading of genomes and calculation and creation of the corresponding data needed for sequence extraction.

The "B" scripts are for creation of "runs" - creation of lists of sampled sequences and searching for homologues.

The "C" scripts are for extraction of sequences from genomes and creation of alignments. Also, pre tool benchmark checks.

The "D" scripts are for the benchmarking of the tools.

The "R" 'R' scripts are for interpreting the results of the benchmarking using 'R'.

The "T" scripts are for benchmarking timing of software.


## Specifics of scripts

### A01-downloadGenomes
Configuration Import - begins by importing global configurations and experiment-specific settings from external configuration files.
Reading Species List - A list of species, along with their accession numbers, lineages, and kingdoms, is read from a file into an array.
Genome Download - iterates over each species in the list and downloads the respective genomes from the NCBI database using the datasets program. The downloaded files include GFF3, genomic sequences, and sequence reports.
Genome Extraction - After downloading, unzips each genome package.
Database Creation - The user is prompted to create a combined FASTA database. If agreed, concatenates all downloaded genomic sequences into a single FASTA file.

### A02-createMergedBeds
Header File Creation - initiates the process by creating header files that store details about each sequence, including the Sequence ID, species accession number, and species name. These header files are used for downstream analyses.
BED File Creation - converts GFF files to BED format, specifying genomic regions for each species.
BED File Subsetting - Separate BED files for coding (CDS) and mRNA regions are created for further analysis.
Merged BED Files - generates merged BED files that include both coding and non-coding regions.
Genomic Length File Creation - A file containing the length of each chromosome or contig is created for each species.
Non-coding Region Identification - calculates non-coding regions as the complement of the mRNA regions. These are stored in separate BED files for positive and negative strands.
Offset Coordinate Calculation - calculates offset coordinates for each coding region, based on its nearest non-coding region longer than 1k. These offsets are stored in new BED files.
Database and Index Creation - creates a database using MMseqs2 and generates an index for the database.
ESL-Sfetch Indexing - Finally, creates indexes for each species' genome using esl-sfetch.

### B01-runPrep
User Input for Sampling Parameters - The script starts by asking the user to input the number of samples they want to randomly select and what they would like to name this run.
Creation of Sampled Exon Beds - The script randomly samples 'n' exons (as specified by the user) from the merged BED files containing both positive and reverse strands. These sampled exon BED files are saved for further analysis.
Generation of Sampled Exon Names - The script extracts the names of the sampled exons from the BED files and saves them in a separate file. This is done to facilitate the creation of corresponding sampled offset BED files.
Creation of Sampled Offset Beds - The script then creates BED files containing the sampled offsets. These are identified by matching the exon names from the sampled exons to the previously generated offset BED files.
Compilation of All Sampled BEDs - Finally, the script concatenates the sampled exon and offset BED files to create a comprehensive list of all sampled BEDs. This will be used for the sequence extraction process.

### B02-cleanNegatives

Runs mmseq to compare reference genomes protein db from Uniprot and the negative set. This will remove any negative sequences that are likely to be protein coding.

### B03-runMmseq
Database and Query Preparation - The script starts by checking if the target MMSEQS2 database exists. If not, it terminates the script. It also checks if the query database exists; if not, it builds it using esl-sfetch and mmseqs.
MMSEQS2 Search - The MMSEQS2 search is run with specified parameters, including the number of threads to use and the search type. The results are saved in the MMSEQS database format.
Result Interpretation - The MMSEQS2 results are converted into a more human-readable tab-delimited format. This is done using the convertalis command of MMSEQS2 with specified output fields.
Result Compilation - The script does additional processing to compile the results. It adds species information, filters out duplicates based on query and species, and extends the coordinates based on the pad value set in the config file. The results are saved in a CSV format for further analysis.
Final Filtering and List Preparation - Finally, the script filters out sequences based on the number of exon matches. Only those sequences with one or more exon matches are retained.


### C01-esl-sfetchMmseqResults
Data Preparation and File Cleanup - Your script starts by loading run files and setting up directories for both the MMSEQS matches and the staged data. You then de-duplicate the MMSEQS matches file to ensure that each match appears only once.
Grouping by Species  You use AWK to split the MMSEQS matches into individual files based on the species. This makes it easier to work with data for each species separately later in the script.
Coordinate Creation - For each species, you create three coordinate files (ExonsCoords.txt, OffNegCoords.txt, OffPosCoords.txt). These files contain the coordinates for sequence extraction. You also ensure that the coordinates are within the sequence length and greater than 0.
Sequence Extraction - You then use esl-sfetch to fetch sequences based on these coordinates. You perform this operation for each of the three types of coordinates (exons, offsets in the negative direction, and offsets in the positive direction).
Sequence File Splitting - Lastly, you use fastaexplode to split the multifasta files into individual fasta files. These files are moved to their respective directories, and a list of created files is saved.


### C02-makeAlignments
Creating CLUSTAL Alignments
Sequence Loop: For each sequence, identify the extracted sequences for Exons, OffPos, and OffNeg across all species. Save these in text files.
Species Loop: Fill the above text files with paths to the actual sequence files.
Running ClustalO: Create alignments using ClustalO. Handle the case where the number of sequences is less than 3 by appending additional lines.
Creating Shuffled CLUSTAL Alignments - Use esl-shuffle to shuffle the alignments, focusing on CDS-only sequences.
Converting to Aligned Fasta Format - Convert the CLUSTAL alignments to aligned FASTA (AFA) format using esl-reformat.
Cleaning AFA Files - Clean the AFA files to have simpler headers, making the data compatible with other software.
Extracting Reference Species Sequences from Shuffled Alignments - Extract the shuffled sequences of the reference species from the shuffled alignments.
Creating Sequence Lists - Create lists of sequences for each type (Exons, OffNeg, OffPos, Shuf).


### C03-createTree
Creates phylogenic trees that are required for benchmarking PhyloCSF.
These need to be opened in a tree viewer such as FigTree, edited to make sure it is bifuricating, then exported and then place in the PhyloCSF_Parameters folder. Also, the newick file cannot use scientific notation, must be decimal, so open the exported file and edit if necessary.

### C04-preBenchmark
Creates a file of nucleotide sizes and GC content for use in timing and summary.

### C05-depthAndId
Creates a file of alignment depth and percent id.

### D01 to D11
Runs the specified software on the previously created sequences and alignments.

### T01 to T11
Timed runs for the specified software. Create a smaller set for timing (by running B and C scripts again with different parameters), rather than running the full set of sequences and alignments created previously.

### R01 to R99
R scripts for interpreting results.