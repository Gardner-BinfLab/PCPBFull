## ---------------------------
##
## Script name: Protein Coding Calculator Benchmark
## Script Six Part 2 - Calculate data for combined clades per software
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

### Multi-purpose ---
# Create clade joined rocs
for (software in software_names) {
  tool_results <- NULL
  tool_results <- combined_tool_results_list[[software]]
  tool_roc_obj_list <- list()  # Initialize the list for storing ROC objects
  combined_tool_results <- NULL
  
  if (!is.null(tool_results)) {
    for (clade in clade_names) {
      combined_tool_results <- rbind(combined_tool_results, tool_results[[clade]])
    }
    
    # Create ROC data and objects
    roc_info <- create_tool_roc_data(combined_tool_results, software)
    
    combined_roc_data_list[[software]] <- roc_info$roc_data
    combined_roc_obj_list[[software]] <- roc_info$roc_object
    
  }
}

### Create DF for combined ROC
for(software in software_names){
  combined_roc_df <- rbind(combined_roc_df, combined_roc_data_list[[software]])
}


###
### Calculate combined ROC metrics
for (software in software_names) {
  
  # Import tool ROC objects
  tool_roc_obj <- combined_roc_obj_list[[software]]
  
  
  # Initialise df
  tool_roc_metrics <- NULL
  tool_roc_metrics <- coords(tool_roc_obj, "best",
                                           best.method="closest.topleft",
                                           ret=c("threshold", "sensitivity", "specificity", "ppv", "fpr", "npv", "tp", "fp", "tn", "fn"),
                                           transpose = TRUE, drop = FALSE)
  # Convert to dataframe
  if (!is.data.frame(tool_roc_metrics)) {
    tool_roc_metrics <- as.data.frame(t(tool_roc_metrics))
  }

  # Clear values
  tp = NULL
  fp = NULL
  fn = NULL
  tn = NULL
  mcc = NULL
  f1 = NULL
  auc = NULL
  auc_ci = NULL
  auc_ci_low = NULL
  auc_ci_up = NULL
  se_ci_low = NULL
  sp_ci_up = NULL
  se_ci_low = NULL
  sp_ci_up = NULL
  mcc_ci = NULL
  tool_ci = NULL
  
  # Calculate MCC and F1 Score
  tp = tool_roc_metrics$tp
  fp = tool_roc_metrics$fp
  fn = tool_roc_metrics$fn
  tn = tool_roc_metrics$tn
  
  mcc <- calculate_mcc(tp, tn, fp, fn)
  f1 <- calculate_f1(tp, fp, fn)
  
  # Calculate AUC and its CI and other CIs
  auc_ci <- ci.auc(tool_roc_obj, conf.level=0.95)
  
  # Set what CIs for return
  rets <- c("threshold", "specificity", "sensitivity")
  tool_ci <- ci.coords(tool_roc_obj, "best", boot.n=5000, best.method="closest.topleft", best.policy="random", ret=rets)
  
  
  #### Maybe add the tool_ci and auc_ci to a list for plot construction? ###
  
  
  # Add MCC, F1, AUC, and AUC CI to the metrics dataframe
  tool_roc_metrics$MCC <- mcc
  tool_roc_metrics$F1 <- f1
  tool_roc_metrics$AUC <- auc_ci[2]
  
  # Add CIs
  tool_roc_metrics$auc_ci_low <- auc_ci[1]  # lower bound of CI
  tool_roc_metrics$auc_ci_up <- auc_ci[3]  # upper bound of CI (3, since 2 is the AUC)
  tool_roc_metrics$sp_ci_low <- tool_ci[[2]][[1]]
  tool_roc_metrics$sp_ci_up <- tool_ci[[2]][[3]]
  tool_roc_metrics$se_ci_low <- tool_ci[[3]][[1]]
  tool_roc_metrics$se_ci_up <- tool_ci[[3]][[3]]
  tool_roc_metrics$mcc_ci_low <- -1
  tool_roc_metrics$mcc_ci_up <- -1
  
  # Add claimed metrics
  this_tool_claimed <- claimed_metrics_df %>% filter(claimed_metrics_df$Software == software)
  tool_roc_metrics$se_claimed <- this_tool_claimed %>% 
    filter(this_tool_claimed$Metric == "Sensitivity") %>% 
    pull(Value)
  tool_roc_metrics$sp_claimed <- this_tool_claimed %>% 
    filter(this_tool_claimed$Metric == "Specificity") %>% 
    pull(Value)
  tool_roc_metrics$mcc_claimed <- this_tool_claimed %>% 
    filter(this_tool_claimed$Metric == "MCC") %>% 
    pull(Value)
  tool_roc_metrics$auc_claimed <- this_tool_claimed %>% 
    filter(this_tool_claimed$Metric == "AUC") %>% 
    pull(Value)
  
  ### Create single auc for each software
  combined_tool_auc <- bind_rows(combined_tool_auc, tibble(Software = software, AUC = auc_ci[2]))
  
  # Add software tool name
  tool_roc_metrics$Software <- software
  
  # Rename some columns
  colnames(tool_roc_metrics) <- gsub("threshold", "Threshold", colnames(tool_roc_metrics))
  colnames(tool_roc_metrics) <- gsub("sensitivity", "Sensitivity", colnames(tool_roc_metrics))
  colnames(tool_roc_metrics) <- gsub("specificity", "Specificity", colnames(tool_roc_metrics))
  colnames(tool_roc_metrics) <- gsub("ppv", "PPV", colnames(tool_roc_metrics))
  colnames(tool_roc_metrics) <- gsub("fpr", "FPR", colnames(tool_roc_metrics))
  colnames(tool_roc_metrics) <- gsub("npv", "NPV", colnames(tool_roc_metrics))
  colnames(tool_roc_metrics) <- gsub("tp", "TP", colnames(tool_roc_metrics))
  colnames(tool_roc_metrics) <- gsub("fp", "FP", colnames(tool_roc_metrics))
  colnames(tool_roc_metrics) <- gsub("tn", "TN", colnames(tool_roc_metrics))
  colnames(tool_roc_metrics) <- gsub("fn", "FN", colnames(tool_roc_metrics))
  
  combined_roc_metrics_list[[software]] <- tool_roc_metrics
}

### Reorder based on AUC
combined_tool_auc <- combined_tool_auc[order(-combined_tool_auc$AUC), ]
combined_tool_auc <- unique(combined_tool_auc)
###
# stopFree ROC comparison
# Load stopFree ROCs
combined_stopFree_roc <- combined_roc_obj_list[["stopFree"]]

for (software in software_names) {
  
  # load comparison ROC and run test
  roc1 <- combined_roc_obj_list[[software]]
  roc_test_result <- roc.test(roc1, combined_stopFree_roc, method="delong")
  
  # Update the name in the 'data.names' field with dynamic software name
  roc_test_result[["data.names"]] <- paste(software, "and stopFree", sep=" ")
  
  # Store the updated result in the list
  combined_roc_clade_comparison_list[[software]] <- roc_test_result
}

###
# randScore ROC comparison
# Load randScore ROCs
combined_randScore_roc <- combined_roc_obj_list[["randScore"]]

for (software in software_names) {
  
  # load comparison ROC and run test
  roc1 <- combined_roc_obj_list[[software]]
  roc_test_result <- roc.test(roc1, combined_randScore_roc, method="delong")
  
  # Update the name in the 'data.names' field with dynamic software name
  roc_test_result[["data.names"]] <- paste(software, "and randScore", sep=" ")
  
  # Store the updated result in the list
  combined_roc_clade_rand_comparison_list[[software]] <- roc_test_result
}


### Create df to send for combined metric plotting
### Create DF for combined ROC
for(software in software_names){
  tool_performance_metrics_df <- rbind(tool_performance_metrics_df, combined_roc_metrics_list[[software]])
}

### make long and ordered
custom_order <- paste(combined_tool_auc$Software)
custom_order <- unique(custom_order)
#
long_tool_performance_metrics_df <- tidyr::gather(tool_performance_metrics_df, 
                                                  key = "Metric", value = "Value", 
                                                  c("AUC", "Sensitivity", "Specificity", "MCC"))
#
long_tool_performance_metrics_df <- long_tool_performance_metrics_df %>%
  mutate(
    Software = factor(Software, levels = custom_order),
    Metric = factor(Metric, levels = c("AUC", "Sensitivity", "Specificity", "MCC"))
  )



# Claimed Metrics order adjust
claimed_metrics_df <- claimed_metrics_df %>% mutate(
                        Software = factor(Software, levels = custom_order),
                        Metric = factor(Metric, levels = c("AUC", "Sensitivity", "Specificity", "MCC")))

