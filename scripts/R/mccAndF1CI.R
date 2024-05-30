# MCC bootstrapping

#for per clade
add_confusion_matrix_calls <- function(data, threshold) {
  data$confusion_matrix <- with(data, ifelse(TrueLabels == "TRUE" & Score >= threshold, "tp",
                                             ifelse(TrueLabels == "FALSE" & Score >= threshold, "fp",
                                                    ifelse(TrueLabels == "FALSE" & Score < threshold, "tn",
                                                           ifelse(TrueLabels == "TRUE" & Score < threshold, "fn", NA)))))
  return(data)
}

add_confusion_matrix_calls_inv <- function(data, threshold) {
  data$confusion_matrix <- with(data, ifelse(TrueLabels == "TRUE" & Score <= threshold, "tp",
                                             ifelse(TrueLabels == "FALSE" & Score <= threshold, "fp",
                                                    ifelse(TrueLabels == "FALSE" & Score > threshold, "tn",
                                                           ifelse(TrueLabels == "TRUE" & Score > threshold, "fn", NA)))))
  return(data)
}

#For combined
add_confusion_matrix_calls_combined <- function(data, threshold) {
  data$confusion_matrix_combined <- with(data, ifelse(TrueLabels == "TRUE" & Score >= threshold, "tp",
                                             ifelse(TrueLabels == "FALSE" & Score >= threshold, "fp",
                                                    ifelse(TrueLabels == "FALSE" & Score < threshold, "tn",
                                                           ifelse(TrueLabels == "TRUE" & Score < threshold, "fn", NA)))))
  return(data)
}

add_confusion_matrix_calls_combined_inv <- function(data, threshold) {
  data$confusion_matrix_combined <- with(data, ifelse(TrueLabels == "TRUE" & Score <= threshold, "tp",
                                             ifelse(TrueLabels == "FALSE" & Score <= threshold, "fp",
                                                    ifelse(TrueLabels == "FALSE" & Score > threshold, "tn",
                                                           ifelse(TrueLabels == "TRUE" & Score > threshold, "fn", NA)))))
  return(data)
}


# For per clade
for (software in software_names) {
  
  for (clade in clade_names) {
    threshold <- roc_metrics_list[[software]][[clade]]$threshold
      if(software == "CPPred"){
        combined_tool_results_list[[software]][[clade]] <- add_confusion_matrix_calls_inv(combined_tool_results_list[[software]][[clade]], threshold)
      }else{
        combined_tool_results_list[[software]][[clade]] <- add_confusion_matrix_calls(combined_tool_results_list[[software]][[clade]], threshold)
      }
  }
}

# For combined
for (software in software_names) {
  
  for (clade in clade_names) {
    threshold <- combined_roc_metrics_list[[software]]$Threshold
    if(software == "CPPred"){
        combined_tool_results_list[[software]][[clade]] <- add_confusion_matrix_calls_combined_inv(combined_tool_results_list[[software]][[clade]], threshold)
    }else{
        combined_tool_results_list[[software]][[clade]] <- add_confusion_matrix_calls_combined(combined_tool_results_list[[software]][[clade]], threshold)
    }
  }
}

extract_confusion_matrix <- function(combined_tool_results_list, software, clade) {
  confusion_matrix <- combined_tool_results_list[[software]][[clade]]$confusion_matrix
  return(confusion_matrix)
}

extract_combined_confusion_matrix <- function(combined_tool_results_list, software, clade) {
  confusion_matrix <- combined_tool_results_list[[software]][[clade]]$confusion_matrix_combined
  return(confusion_matrix)
}


boot_function <- function(data, indices) {
  sampled_data <- data[indices]
  
  # Count occurrences
  tp <- sum(sampled_data == "tp")
  tn <- sum(sampled_data == "tn")
  fp <- sum(sampled_data == "fp")
  fn <- sum(sampled_data == "fn")
  
  # Calculate MCC and F1
  mcc <- calculate_mcc(tp, tn, fp, fn)
  
  return(MCC = mcc)
}

# Define MCC and F1 calculation functions with additional checks
calculate_mcc <- function(tp, tn, fp, fn) {
  tp <- as.numeric(tp)
  tn <- as.numeric(tn)
  fp <- as.numeric(fp)
  fn <- as.numeric(fn)
  
  numerator <- (tp * tn) - (fp * fn)
  denominator <- sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn))
  if (is.na(denominator) || denominator == 0) return(0)  # Avoid division by zero or NA values
  return(numerator / denominator)
}

library(boot)
mcc_ci_list <- list()
for (software in software_names) {
    
    #Initialize list to store ROC metrics per software
    mcc_ci_clade_list <- list()
    
    for (clade in clade_names) {
      # Extract confusion matrix
      confusion_matrix <- extract_confusion_matrix(combined_tool_results_list, software, clade)
      
      # Perform bootstrapping
      set.seed(123)  # For reproducibility
      boot_results <- boot(data = confusion_matrix, statistic = boot_function, R = 5000)
      boot_ci_results <- boot.ci(boot.out = boot_results, type = "basic")
      mcc_ci_clade_list[[clade]] <- boot_ci_results
    }
    mcc_ci_list[[software]] <- mcc_ci_clade_list
}


for (software in software_names) {
  tool_roc_metrics_list <- roc_metrics_list[[software]]
  
  if (!is.null(tool_roc_metrics_list)) {
    for (clade in names(tool_roc_metrics_list)) {
      metrics <- tool_roc_metrics_list[[clade]]
      
      # Add MCC CIs to the metrics dataframe
      metrics$MCC_CI_Lower <- mcc_ci_list[[software]][[clade]][[4]][[4]]
      metrics$MCC_CI_Upper <- mcc_ci_list[[software]][[clade]][[4]][[5]]
      
      # Store updated metrics back in the list
      tool_roc_metrics_list[[clade]] <- metrics
    }
    
    # Store updated list in the main list
    roc_metrics_list[[software]] <- tool_roc_metrics_list
  }
}


## Combined mcc CIs



mcc_ci_combined_list <- list()
for (software in software_names) {
  
  # Initialize a combined confusion matrix for the software
  combined_confusion_data <- c()
  
  for (clade in clade_names) {
    # Extract confusion matrix for each clade
    confusion_matrix <- extract_combined_confusion_matrix(combined_tool_results_list, software, clade)
    
    # Add the confusion matrix to the combined confusion matrix
    combined_confusion_data <- c(combined_confusion_data, confusion_matrix)
  }
  
    # Perform bootstrapping on the combined confusion matrix
  set.seed(123)  # For reproducibility
  boot_results <- boot(data = combined_confusion_data, statistic = boot_function, R = 12000)
  boot_ci_results <- boot.ci(boot.out = boot_results, type = "basic")
  
  # Store the results in the list
  mcc_ci_combined_list[[software]] <- boot_ci_results
}



for (software in software_names) {
  metrics <- combined_roc_metrics_list[[software]]
      
      # Add MCC CIs to the metrics dataframe
      metrics$mcc_ci_low <- mcc_ci_combined_list[[software]][[4]][[4]]
      metrics$mcc_ci_up <- mcc_ci_combined_list[[software]][[4]][[5]]

    # Store updated list in the main list
    combined_roc_metrics_list[[software]] <- metrics
}
