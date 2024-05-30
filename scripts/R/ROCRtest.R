library(tidyverse)  # for data manipulation
library(dlstats)    # for package download stats
library(pkgsearch)  # for searching packages

rocPkg <-  pkg_search(query="ROC",size=200)

rocPkgShort <- rocPkg %>% 
  filter(maintainer_name != "ORPHANED", score > 190) %>%
  select(score, package, downloads_last_month) %>%
  arrange(desc(downloads_last_month))
head(rocPkgShort)


install.packages("ROCR")
library(ROCR)

compute_metrics <- function(true_labels, scores) {
  pred <- prediction(scores, true_labels)
  auc <- performance(pred, "auc")@y.values[[1]]
  
  # ROC curve (x = fpr, y = tpr)
  roc_perf <- performance(pred, "tpr", "fpr")
  
  # Find the point closest to the top-left corner (0,1)
  fpr <- roc_perf@x.values[[1]]
  tpr <- roc_perf@y.values[[1]]
  distance <- sqrt((fpr - 0)^2 + (tpr - 1)^2)
  optimal_index <- which.min(distance)
  optimal_cutoff <- roc_perf@alpha.values[[1]][optimal_index]
  predictions <- ifelse(scores >= optimal_cutoff, TRUE, FALSE)
  
  # Confusion Matrix
  tp <- sum(predictions == TRUE & true_labels == TRUE)
  tn <- sum(predictions == FALSE & true_labels == FALSE)
  fp <- sum(predictions == TRUE & true_labels == FALSE)
  fn <- sum(predictions == FALSE & true_labels == TRUE)
  
  sensitivity <- tp / (tp + fn)
  specificity <- tn / (tn + fp)
  ppv <- tp / (tp + fp)
  npv <- tn / (tn + fn)
  f1 <- 2 * tp / (2 * tp + fp + fn)
  mcc <- calculate_mcc(tp, tn, fp, fn)
  fpr <- fp / (fp + tn)
  
  return(c(AUC = auc, Sensitivity = sensitivity, Specificity = specificity, PPV = ppv, 
           NPV = npv, F1 = f1, MCC = mcc, FPR = fpr))
}

bootstrap_ci <- function(true_labels, scores, n_bootstrap = 1000) {
  metric_names <- c("AUC", "Sensitivity", "Specificity", "PPV", "NPV", "F1", "MCC", "FPR")
  boot_results <- boot(data = data.frame(true_labels, scores), 
                       statistic = function(data, indices) {
                         d <- data[indices, ]
                         compute_metrics(d$true_labels, d$scores)
                       }, R = n_bootstrap)
  
  ci <- apply(boot_results$t, 2, function(x) quantile(x, c(0.025, 0.975)))
  
  results <- compute_metrics(true_labels, scores)
  names(results) <- metric_names
  results_ci <- matrix(ci, nrow = 2, dimnames = list(c("Lower", "Upper"), metric_names))
  
  return(list(Results = results, CI = results_ci))
}

results_list <- list()

for (software in software_names) {
  for (clade in clade_names) {
    data <- combined_tool_results_list[[software]][[clade]]
    true_labels <- data$TrueLabels
    scores <- data$Score
    metrics <- bootstrap_ci(true_labels, scores)
    results_list[[software]][[clade]] <- metrics
  }
}


#REporting
collect_results <- function(results_list, software_names, clade_names) {
  result_data <- data.frame(
    Software = character(),
    Clade = character(),
    AUC = numeric(),
    AUC_CI_Lower = numeric(),
    AUC_CI_Upper = numeric(),
    Sensitivity = numeric(),
    Sensitivity_CI_Lower = numeric(),
    Sensitivity_CI_Upper = numeric(),
    Specificity = numeric(),
    Specificity_CI_Lower = numeric(),
    Specificity_CI_Upper = numeric(),
    MCC = numeric(),
    MCC_CI_Lower = numeric(),
    MCC_CI_Upper = numeric(),
    PPV = numeric(),
    FPR = numeric(),
    NPV = numeric(),
    F1 = numeric(),
    stringsAsFactors = FALSE
  )
  
  for (software in software_names) {
    for (clade in clade_names) {
      metrics <- results_list[[software]][[clade]]
      result_data <- rbind(result_data, data.frame(
        Software = software,
        Clade = clade,
        AUC = metrics$Results["AUC"],
        AUC_CI_Lower = metrics$CI["Lower", "AUC"],
        AUC_CI_Upper = metrics$CI["Upper", "AUC"],
        Sensitivity = metrics$Results["Sensitivity"],
        Sensitivity_CI_Lower = metrics$CI["Lower", "Sensitivity"],
        Sensitivity_CI_Upper = metrics$CI["Upper", "Sensitivity"],
        Specificity = metrics$Results["Specificity"],
        Specificity_CI_Lower = metrics$CI["Lower", "Specificity"],
        Specificity_CI_Upper = metrics$CI["Upper", "Specificity"],
        MCC = metrics$Results["MCC"],
        MCC_CI_Lower = metrics$CI["Lower", "MCC"],
        MCC_CI_Upper = metrics$CI["Upper", "MCC"],
        PPV = metrics$Results["PPV"],
        FPR = metrics$Results["FPR"],
        NPV = metrics$Results["NPV"],
        F1 = metrics$Results["F1"]
      ))
    }
  }
  
  return(result_data)
}

results_df <- collect_results(results_list, software_names, clade_names)
View(results_df)
# Export to CSV
write.csv(results_df, "results_report.csv", row.names = FALSE)
