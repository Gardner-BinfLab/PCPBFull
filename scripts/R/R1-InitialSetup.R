## ---------------------------
##
## Script name: Protein Coding Calculator Benchmark
## Script One - Initial setup
##  - Library Import
##  - Define Setup Functions
##  - Initialise Setup Data
##  - Import Setup Data
##
## Purpose of script: 
##
## Author: DJ Champion
##
## Date Created: 2023
##
## Copyright (c) DJ Champion, 2023
## Email: dj.champion@otago.ac.nz
##
## ---------------------------
##
## Notes: For the University of Otago, Biochemistry group Gardner Lab project
##
## ---------------------------

### Library Import ----
library(pROC)
library(ggplot2)
library(tidyr)
library(dplyr)
library(ggbeeswarm)
library(forcats)
library(stringr)
library(readr)
library(scales)
library(tidyverse)

### Define Setup Functions ----

# Function to read the CSV file with error handling
read_csv_file <- function(filename, has_headers = TRUE) {
  tryCatch({
    read.csv(filename, header = has_headers, blank.lines.skip = TRUE, stringsAsFactors = FALSE)
  }, warning = function(w) {
    message("Warning: ", conditionMessage(w))
    return(NULL)
  }, error = function(e) {
    message("Error: ", conditionMessage(e), " File: ", filename)
    return(NULL)
  }, finally = {})
}

### Import Setup Data
software_data <- read_csv_file("setupData/software_names.csv", has_headers = FALSE)
clade_names <- readLines("setupData/clade_names.txt")
claimed_metrics_df <- read_csv_file("setupData/claimed_metrics.csv")
phylo_names <- read_csv_file("setupData/phyloNames.csv", has_headers = FALSE)
clade_conversion <- read_csv_file("setupData/clade_conversion.csv", has_headers = FALSE)
freq_setup <- read_csv_file("setupData/freq_setup.csv")
software_3frame <- readLines("setupData/software_3frameNames.csv")
software_6frame <- readLines("setupData/software_6frameNames.csv")
revComp_run_conversion <- read_csv_file("setupData/revComp_run_conversion.csv", has_headers = FALSE)

# Extract software names and colors
software_names <- software_data[[1]] # Assuming software names are in the first column
software_colors <- setNames(software_data[[2]], software_data[[1]]) # Assuming colors are in the second column, and set names as software names

