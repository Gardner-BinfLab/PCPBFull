## ---------------------------
##
## Script name: Protein Coding Calculator Benchmark
## Script Three - Variable and constant value settings
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

# Common FPR slices (100)
common_fpr <- seq(0, 1, by = 0.01)

# For renaming things
label_mapping <- setNames(c("Coding", "Intergenic", "Shuffled"), c("Positive", "Off", "Shuf"))

# Define known prefixes
seq_prefixes <- c("Shuf", "OffNeg", "OffPos")

# In R3-VarAndConstValues.R
# Constants for score separation
label_off <- "Off"
label_shuf <- "Shuf"

# Define a custom labeller function (Yes, technically a function, but acts as a variable)
clade_labeller <- as_labeller(c(catGroup = "Animalia", fungiGroup = "Fungi", melonGroup = "Plantae"))

### Plot related ----

# Box and Whisker save file name suffix
common_word_baw <- "20240513-BaW"

# Freq name save file suffix
common_word_freq <- "20240513-freq"

#
common_word_vio <- "20240513-violin"

# Run name (number)
run_name <- "1200"

# RevComp names
revComp_clade_name <- "revComp"
