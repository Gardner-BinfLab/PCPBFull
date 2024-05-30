## ---------------------------
##
## Script name: Protein Coding Calculator Benchmark
## Script Five - Import data
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

### Prep
### Copy 6-frames to bestScore
for(software in software_6frame){
  for(clade in clade_names){
    forwardFilename <- file.path("data/forward", paste(software, clade, run_name, "compiled.csv", sep = "_"))
    bestFilename <- file.path("data/bestScores", paste(software, clade, run_name, "compiled.csv", sep = "_"))
    file.copy(forwardFilename, bestFilename)
  }
}

### Compile best scores from forward or revcomp for 3-frame software
software <-NULL
for(software in software_3frame){
  software_df <- list()
  
  for (clade in clade_names) {
    
    revCompRunName <- subset(revComp_run_conversion, V1 == clade)$V2
    # Filenames
    forwardFilename <- file.path("data/forward", paste(software, clade, run_name, "compiled.csv", sep = "_"))
    revCompFilename <- file.path("data/reverse", paste(software, revComp_clade_name, revCompRunName, "compiled.csv", sep = "_"))
    bestFilename <- file.path("data/bestScores", paste(software, clade, run_name, "compiled.csv", sep = "_"))
    
    # Load the data
    forward_df <- read_csv_file(forwardFilename)
    reverse_df <- read_csv_file(revCompFilename)
    
    # Prepare the 'Name' column using the adjust_name function
    forward_df <- forward_df %>%
      mutate(Name = sapply(Name, adjust_name, prefixes = seq_prefixes)) %>% 
      mutate(Direction = "forward")
    reverse_df <- reverse_df %>%
      mutate(Name = sapply(Name, adjust_name, prefixes = seq_prefixes)) %>% 
      mutate(Direction = "reverse")
    
    # Combine all clades into one dataframe and sort
    software_combined_df <- bind_rows(forward_df, reverse_df) %>% arrange(Name)
    
    # Perform pairwise comparison and keep only one row with the highest or lowest 'Score'
    # Add additional sorting by row_number() to break ties
    best_scores_df <- software_combined_df %>%
      group_by(Name) %>%
      mutate(RowNum = row_number()) %>%  # Assign a unique row number within each group
      filter(if(software == "CPPred") {
        Score == min(Score)  # For CPPred, select rows with the minimum score
      } else {
        Score == max(Score)  # For other software, select rows with the maximum score
      }) %>%
      slice_min(order_by = RowNum, n = 1) %>%  # Pick the first row in case of ties
      ungroup() %>%
      select(-RowNum)  # Remove the auxiliary RowNum column
    
    # Save to a new CSV file for use further in the pipeline
    write_csv(best_scores_df, bestFilename)
  }
}


### Clade length data ----
# Loop through each clade name to load their respective sequence length data
for (clade in clade_names) {
  filename <- paste0(clade,"_", run_name, "_sequenceSizes.csv")  # Construct the filename
  # Assuming the files are in a folder named 'seqLengths'
  filepath <- file.path("seqLengths", filename)
  
  if (file.exists(filepath)) {
    # Read the data without headers and assign column names
    seq_data <- read.csv(filepath, header = FALSE, col.names = c("Name", "Length", "GC_Content"))
    
    # Store the data in the list, using the clade name as the key
    clade_seq_lengths[[clade]] <- seq_data
    
    # Create length data for negative controls (all same length as poitive controls)
    clade_seq_lengths[[clade]] <- expand_seq_data(clade_seq_lengths[[clade]], seq_prefixes)
  }
}

### Software tool results data ----
# Loop through each software and load their respective results
# Add length data
# Add to dataframes, lists
for (software in software_names) {
  software_df <- list()
  
  # Debug messages
  print(paste("Now working on: ", software))
  for (clade in clade_names) {
    filename <- file.path("data/bestScores", paste(software, clade, run_name, "compiled.csv", sep = "_"))
    if (file.exists(filename)) {
      print(paste("In the clade: ", clade))
      tool_results <- read_csv_file(filename)
      if (!is.null(tool_results)) {
        
        # Apply the function to the Name column after reading in the data
        tool_results$Name <- sapply(tool_results$Name, adjust_name, seq_prefixes)
        
        # Apply Control labels based on name prefixes
        tool_results$ControlLabel <- sapply(tool_results$Name, label_from_name, seq_prefixes)
        
        # Check if this clade's sequence length data is available
        if (!is.null(clade_seq_lengths[[clade]])) {
          seq_lengths <- clade_seq_lengths[[clade]]
          
          # Assuming seq_lengths is the sequence length dataframe for the current clade
          tool_results <- merge(tool_results, seq_lengths, by = "Name", all.x = TRUE)
        }
        
        # Remove any lines with no score (if needed...)
        # tool_results <- tool_results %>% filter(!is.na(Score))
        
        # Add needed cloumns
        tool_results$Clade <- clade  # Add a clade column
        tool_results$Software <- software  # Add a software column
        
        # Create truth labels
        tool_results <- tool_results %>%
          mutate(TrueLabels = case_when(
            ControlLabel == "Intergenic" ~ FALSE,
            ControlLabel == "Shuffled" ~ FALSE,
            TRUE ~ TRUE))

        # Create verdict labels
        tool_results <- tool_results %>% update_verdict
        
        # Keep full results first
        software_df[[clade]] <- tool_results
      }
    }
  }

  combined_tool_results_list[[software]] <- software_df
}

