## ---------------------------
##
## Script name: Protein Coding Calculator Benchmark
## Script Two - Global Initialisation
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

### Initialisation ----

# Initialise ROC data List
roc_data_list <- list()

# Initialise ROC object list
roc_obj_list <- list()

# Initialise tool roc metrics
roc_metrics_list <- list()

# Initialize ROC comparison list
roc_comparison_list <- list()
roc_rand_comparison_list <- list()


# Initialise list to store ROC comparison
combined_roc_clade_comparison_list <- list()

# Initialise list to store ROC comparison
combined_roc_clade_rand_comparison_list <- list()

# Combined roc data and obj and metrics lists
combined_roc_data_list <- list()
combined_roc_obj_list <- list()
combined_roc_metrics_list <- list()

# AUC list
# Create an empty data frame with the desired structure
combined_tool_auc <- tibble(Software = character(), AUC = numeric())

# Initialse combined ROC DF
combined_roc_df <- NULL
# Initialse true false count list per software
true_false_counts <- list()

# Initialise true false count list for all software
true_false_counts_list <- list()

# Initialise an empty data frame to hold all density data
all_density_data <- data.frame(Software = character(), Clade = character(),
                               Score = numeric(), Label = character())

# Initialise combined list for tool score results only
combined_tool_results_list <- list()

# Initialise combined normalised score limits list
software_normScore_limits <- list()

# Initialise list for bestScoring
bestDfList <- list()

# Initialize a list to store the frequency data for each software
software_freqs <- list()

# Initialize a list to store each clade's sequence length data
clade_seq_lengths <- list()

# Initialise the lists to store data frames
raw_results_list <- list()
results_list <- list()
total_counts_list <- list()
compiled_scores <- list()

# Initialize global min and max score trackers if not already present
global_min_scores <- list()
global_max_scores <- list()

# Initialise an empty data frame to hold mean counts
combined_total_counts <- data.frame()

# Initialize an empty list to store the combined normScore results
wide_normScore_list <- list()

# Initialize an empty list to store the combined score results
wide_score_list <- list()

# Initialize software_tool_info dataframe
software_tool_info <- data.frame(Software = character(), Clade = character(), TotalTrue = logical(), TotalFalse = logical(), stringsAsFactors = FALSE)

# Initialise df
software_tool_info <- NULL

# Initialise clade_performance_metrics_df
clade_performance_metrics_df <- data.frame(
  Software = character(),
  Clade = character(),
  AUC = numeric(),
  Sensitivity = numeric(),
  Specificity = numeric(),
  FPR = numeric(),
  MCC = numeric(),
  PPV = numeric(),
  NPV = numeric(),
  FScore = numeric(),
  stringsAsFactors = FALSE
)

# Initialise tool_performance_metrics_df
tool_performance_metrics_df <- data.frame(
  Software = character(),
  AUC = numeric(),
  Sensitivity = numeric(),
  Specificity = numeric(),
  FPR = numeric(),
  MCC = numeric(),
  PPV = numeric(),
  NPV = numeric(),
  FScore = numeric(),
  stringsAsFactors = FALSE
)

