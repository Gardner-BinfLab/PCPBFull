## ---------------------------
##
## Script name: Protein Coding Calculator Benchmark
## Script Tool - Keep best score.
##
## Purpose of script: 
## Run before R5. Because we had to run the reverse complements on some tools,
## this will keep the best score from the two runs.
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
    
    software_df[[clade]] <- best_scores_df
    
    # Save to a new CSV file for use further in the pipeline
    write_csv(best_scores_df, bestFilename)
  }
  
  bestDfList[[software]] <- software_df
  
}
