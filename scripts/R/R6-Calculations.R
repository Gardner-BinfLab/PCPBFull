## ---------------------------
##
## Script name: Protein Coding Calculator Benchmark
## Script Six - Calculate more useful data from data
##
## Purpose of script:
##  Creates true false counts
##  Creates ROC objects
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

### Multi-purpose ---
# Grab true false counts
# Create roc objects
for (software in software_names) {
  tool_results <- combined_tool_results_list[[software]]
  true_false_counts <- list()
  
  if (!is.null(tool_results)) {
    tool_roc_obj_list <- list()  # Initialize the list for storing ROC objects
    
    for (clade in clade_names) {
      results <- process_clade_results(tool_results[[clade]], clade)
      
      # Update true_false_counts
      true_false_counts[[clade]] <- data.frame(
                                            TotalTrue = results$true_count, 
                                            TotalFalse = results$false_count)
      
      # Create ROC data and objects
      roc_info <- create_roc_data(results$clade_results, software, clade)
      roc_data_list[[software]][[clade]] <- roc_info$roc_data
      tool_roc_obj_list[[clade]] <- roc_info$roc_object
    }
    # add to true false list
    true_false_counts_list[[software]] <- true_false_counts
    
    # add ROC to roc obj list
    if (length(tool_roc_obj_list) > 0) {
      roc_obj_list[[software]] <- tool_roc_obj_list
    }
  }
}



###
### Calculate individual ROC data
for (software in software_names) {
  
  # Import tool ROC objects
  tool_roc_objs <- roc_obj_list[[software]]
  
  if (!is.null(tool_roc_objs)) {
    
    #Initialize list to store ROC metrics per software
    tool_roc_metrics_list <- list()
    
    for (clade in clade_names) {
      # Initialise list for all clade metrics
      tool_roc_metrics_list[[clade]] <- coords(tool_roc_objs[[clade]], "best",
                      best.method="closest.topleft",
                      ret=c("threshold", "sensitivity", "specificity", "ppv", "fpr", "npv", "tp", "fp", "tn", "fn"))
    }
    
    if (length(tool_roc_metrics_list) > 0) {
      roc_metrics_list[[software]] <- tool_roc_metrics_list
    }
  }
}


###
# Calculate MCC, F1, AUC, and CI
for (software in software_names) {
  tool_roc_objs <- roc_obj_list[[software]]
  
  if (!is.null(tool_roc_objs)) {
    tool_roc_metrics_list <- list()  # Initialize list to store ROC metrics per software
    
    for (clade in names(tool_roc_objs)) {
      roc_obj <- tool_roc_objs[[clade]]
      
      # Retrieve existing metrics
      metrics <- roc_metrics_list[[software]][[clade]]
      
      # Calculate MCC and F1 Score
      tp = metrics$tp
      fp = metrics$fp
      fn = metrics$fn
      tn = metrics$tn
      
      mcc <- calculate_mcc(tp, tn, fp, fn)
      f1 <- calculate_f1(tp, fp, fn)
      
      # Calculate AUC and its CI
      rets <- c("threshold", "specificity", "sensitivity")
      auc_ci <- ci(roc_obj)
      tool_ci <- ci.coords(roc_obj, "best", best.method="closest.topleft", best.policy="random", ret=rets)
      
      # Add MCC, F1, AUC, and AUC CI to the metrics dataframe
      metrics$MCC <- mcc
      metrics$F1 <- f1
      metrics$AUC <- auc_ci[2]
      metrics$AUC_CI_Lower <- auc_ci[1]  # lower bound of CI
      metrics$AUC_CI_Upper <- auc_ci[3]  # upper bound of CI
      metrics$sp_ci_low <- tool_ci[[2]][[1]]
      metrics$sp_ci_up <- tool_ci[[2]][[3]]
      metrics$se_ci_low <- tool_ci[[3]][[1]]
      metrics$se_ci_up <- tool_ci[[3]][[3]]
      
      # Store updated metrics back in the list
      tool_roc_metrics_list[[clade]] <- metrics
    }
    
    # Store updated list in the main list
    roc_metrics_list[[software]] <- tool_roc_metrics_list
  }
}




###
# stopFree ROC comparison
for (clade in names(tool_roc_objs)) {
  
  # Initialise list to store ROC comparison per clade
  roc_clade_comparison_list <- list()
  
  # Load stopFree ROCs
  stopFree_roc <- roc_obj_list[["stopFree"]][[clade]]
  
  for (software in software_names) {
    
    # load comparison ROC and run test
    roc1 <- roc_obj_list[[software]][[clade]]
    roc_test_result <- roc.test(roc1, stopFree_roc, method = "delong")
    
    # Update the name in the 'data.names' field with dynamic software name
    roc_test_result[["data.names"]] <- paste(software, "and stopFree", sep=" ")
    
    # Store the updated result in the list
    roc_clade_comparison_list[[software]] <- roc_test_result
  }
  
  # Store per clade data
  roc_comparison_list[[clade]] <- roc_clade_comparison_list
}

# randScore ROC comparison
for (clade in names(tool_roc_objs)) {
  
  # Initialise list to store ROC comparison per clade
  roc_clade_rand_comparison_list <- list()
  
  # Load stopFree ROCs
  randScore_roc <- roc_obj_list[["randScore"]][[clade]]
  
  for (software in software_names) {
    
    # load comparison ROC and run test
    roc1 <- roc_obj_list[[software]][[clade]]
    roc_test_result <- roc.test(roc1, randScore_roc, method = "delong")
    
    # Update the name in the 'data.names' field with dynamic software name
    roc_test_result[["data.names"]] <- paste(software, "and randScore", sep=" ")
    
    # Store the updated result in the list
    roc_clade_rand_comparison_list[[software]] <- roc_test_result
  }
  
  # Store per clade data
  roc_rand_comparison_list[[clade]] <- roc_clade_rand_comparison_list
}


### Calculate global_min and global_max for each software
for (software in software_names) {
  software_scores <- c()
  for(clade in clade_names) {
    software_scores <- c(software_scores, combined_tool_results_list[[software]][[clade]]$Score)
  }
  
  global_min_scores[[software]] <- min(software_scores)
  global_max_scores[[software]] <- max(software_scores)
}




### Normalize scores & find nice limits for plots
for (software in software_names) {
  # Filter data for the current software tool
  sw_data <- bind_rows(combined_tool_results_list[[software]])
  
  # Separate the scores based on the new labels
  positive_scores <- sw_data %>% filter(ControlLabel == "Coding") %>% pull(Score)
  off_scores <- sw_data %>% filter(ControlLabel == "Intergenic") %>% pull(Score)
  shuf_scores <- sw_data %>% filter(ControlLabel == "Shuffled") %>% pull(Score)
  
  # Combine all scores to normalize
  all_scores <- c(positive_scores, off_scores, shuf_scores)
  global_min <- global_min_scores[[software]]
  global_max <- global_max_scores[[software]]
  
  # Normalize the scores
  epsilon <- abs(0.01 * (global_max - global_min))

  # Calculate the normalized scores
  sw_data <- sw_data %>%
    mutate(normScore = log10((Score - global_min_scores[[software]] + epsilon) / 
                               (global_max_scores[[software]] - global_min_scores[[software]] + epsilon)))
  
  # Update the combined_tool_results_list with normalized scores
  for (clade in names(combined_tool_results_list[[software]])) {
    # Extract the relevant subset from sw_data
    clade_data <- sw_data %>% filter(Clade == clade)
    
    # Update the corresponding part of the combined_tool_results_list
    combined_tool_results_list[[software]][[clade]] <- clade_data
  }
  
  # Calculate the upper and lower bounds for each clade
  x_limits <- sw_data %>%
    group_by(ControlLabel) %>%
    summarise(
      Q1 = quantile(normScore, 0.25),
      Q3 = quantile(normScore, 0.75)
    ) %>%
    mutate(
      Lower = pmax(Q1 - 1.2 * (Q3 - Q1), -2.0),
      Upper = pmin(Q3 + 1.2 * (Q3 - Q1), 0)
    ) %>% ungroup()
  
  # Add limits to software info
  software_normScore_limits[[software]] <- x_limits
  
  # import freq setup
  range_size <- freq_setup %>% filter(Software == software) %>% pull(Bins)
    
  # Calculate relative frequencies
  # freq_data <- sw_data %>%
  #   group_by(ControlLabel, Clade, normScore = cut_width(normScore, width = range_size, boundary = 0)) %>%
  #   summarise(count = n(), .groups = 'drop') %>%
  #   mutate(relative_freq = count / sum(count))
  
  # Store the computed frequencies in a list for later use
  #software_freqs[[software]] <- freq_data
  
}

# Make wide list of normScores and sum
# Loop through each software
for (software in software_names) {
  # Initialize an empty data frame for this software
  software_wide <- data.frame(Name=character(), stringsAsFactors=FALSE)
  
  # Loop through each clade within the software
  for (clade in clade_names) {
    # Extract the relevant columns (Name and normScore)
    clade_data <- combined_tool_results_list[[software]][[clade]][, c("Name", "normScore")]
    
    # Add a new column for the clade name
    clade_data$Clade <- clade
    
    # Rename the normScore column to software name
    colnames(clade_data)[2] <- software
    
    # If the software-wide data frame is empty, copy the clade data directly
    if (nrow(software_wide) == 0) {
      software_wide <- clade_data
    } else {
      # Otherwise, merge with existing data on Name
      software_wide <- rbind(software_wide, clade_data)
    }
  }
  
  # Add the wide-format data for this software to the list
  wide_normScore_list[[software]] <- software_wide
}

# Extract unique Name and Clade pairs from all tools
name_clade_pairs <- do.call(rbind, lapply(wide_normScore_list, function(df) df[, c("Name", "Clade")]))
unique_name_clade_pairs <- unique(name_clade_pairs)

# Start with a data frame that contains unique Names and their associated Clades
final_wide_format <- unique_name_clade_pairs

# Loop through each software tool and join its data with the final_wide_format
for (software in names(wide_normScore_list)) {
  # Prepare the software-specific data frame; ensure it has Name, Clade, and the normScore
  software_df <- select(wide_normScore_list[[software]], Name, Clade, matches(software))
  
  # Join with the final wide-format data frame
  final_wide_format <- full_join(final_wide_format, software_df, by = c("Name", "Clade"))
}



# Make wide list of Scores
# Loop through each software
for (software in software_names) {
  # Initialize an empty data frame for this software
  software_wide <- data.frame(Name=character(), stringsAsFactors=FALSE)
  
  # Loop through each clade within the software
  for (clade in clade_names) {
    # Extract the relevant columns (Name and normScore)
    clade_data <- combined_tool_results_list[[software]][[clade]][, c("Name", "Score")]
    
    # Add a new column for the clade name
    clade_data$Clade <- clade
    
    # Rename the normScore column to software name
    colnames(clade_data)[2] <- software
    
    # If the software-wide data frame is empty, copy the clade data directly
    if (nrow(software_wide) == 0) {
      software_wide <- clade_data
    } else {
      # Otherwise, merge with existing data on Name
      software_wide <- rbind(software_wide, clade_data)
    }
  }
  
  # Add the wide-format data for this software to the list
  wide_score_list[[software]] <- software_wide
}

# Extract unique Name and Clade pairs from all tools
name_clade_pairs <- do.call(rbind, lapply(wide_score_list, function(df) df[, c("Name", "Clade")]))
unique_name_clade_pairs <- unique(name_clade_pairs)

# Start with a data frame that contains unique Names and their associated Clades
scores_final_wide_format <- unique_name_clade_pairs

# Loop through each software tool and join its data with the final_wide_format
for (software in names(wide_score_list)) {
  # Prepare the software-specific data frame; ensure it has Name, Clade, and the normScore
  software_df <- select(wide_score_list[[software]], Name, Clade, matches(software))
  
  # Join with the final wide-format data frame
  scores_final_wide_format <- full_join(scores_final_wide_format, software_df, by = c("Name", "Clade"))
}
