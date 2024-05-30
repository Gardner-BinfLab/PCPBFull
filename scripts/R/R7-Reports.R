## ---------------------------
##
## Script name: Protein Coding Calculator Benchmark
## Script Seven - Reports
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


###
# Large Results CSV
write.csv(scores_final_wide_format, file = "all_scores.csv")
###
# Per tool roc metrics
tool_performance_metrics_df <- tibble()
for(software in software_names){
  tool_performance_metrics_df <- rbind(tool_performance_metrics_df, combined_roc_metrics_list[[software]])
}
for_reporting <- tool_performance_metrics_df
for_reporting <- for_reporting %>% mutate("x/N" = 1, "Diff. from stopFree Z-score" = NaN, "Diff. from stopFree p-val" = NaN, "Diff. from randScore Z-score" = NaN, "Diff. from randScore p-val" = NaN, "Median Speed kb/sec" = NaN, "Clade" = "Combined")

for_reporting <- for_reporting %>% 
  select("Software", "x/N", "Sensitivity",
         "Specificity", "PPV", "FPR", "NPV",
         "F1", "AUC", "MCC", AUC_CI_Lower = auc_ci_low,
         AUC_CI_Upper = auc_ci_up, Spe_CI_Lower = sp_ci_low, Spe_CI_Upper = sp_ci_up, Sen_CI_Lower = se_ci_low, Sen_CI_Upper = se_ci_up, MCC_CI_Lower = mcc_ci_low, MCC_CI_Upper = mcc_ci_up, "Diff. from stopFree Z-score",
         "Diff. from stopFree p-val", "Diff. from randScore Z-score", "Diff. from randScore p-val","Median Speed kb/sec", "Clade")


for(i in 1:nrow(for_reporting)){
  software <- for_reporting$Software[i]
  #stopFree
  for_reporting$`Diff. from stopFree Z-score`[i] <- combined_roc_clade_comparison_list[[software]][["statistic"]][[1]]
  for_reporting$`Diff. from stopFree p-val`[i] <- combined_roc_clade_comparison_list[[software]][["p.value"]]
  #randScore
  for_reporting$`Diff. from randScore Z-score`[i] <- combined_roc_clade_rand_comparison_list[[software]][["statistic"]][[1]]
  for_reporting$`Diff. from randScore p-val`[i] <- combined_roc_clade_rand_comparison_list[[software]][["p.value"]]
  
}


View(for_reporting)
write.csv(for_reporting, file = "combined_roc_report.csv")


### Per clade roc metrics
per_clade_tool_roc_metrics <- data.frame()
for(software in software_names){

  for(clade in clade_names){
    # Combine the current dataframe with the new data
    # Also, add 'Clade' and 'Software' columns on the fly
    temp_data <- roc_metrics_list[[software]][[clade]] %>%
      mutate(Clade = clade, Software = software)
    
    # Bind the newly formed dataframe with the main dataframe
    per_clade_tool_roc_metrics <- rbind(per_clade_tool_roc_metrics, temp_data)
  }

}
  

clade_for_reporting <- per_clade_tool_roc_metrics
clade_for_reporting <- clade_for_reporting %>% mutate("x/N" = 1, "Diff. from stopFree Z-score" = NaN,
                                                      "Diff. from stopFree p-val" = NaN,
                                                      "Diff. from randScore Z-score" = NaN,
                                                      "Diff. from randScore p-val" = NaN,
                                                      "Median Speed kb/sec" = NaN,)

clade_for_reporting <- clade_for_reporting %>% 
  select("Software", "x/N", "Sensitivity" = sensitivity,
         "Specificity" = specificity, "PPV" = ppv, "FPR" = fpr, "NPV" = npv,
         "F1", "AUC", "MCC", AUC_CI_Lower,
         AUC_CI_Upper, sp_ci_low, sp_ci_up, se_ci_low,se_ci_up, MCC_CI_Lower, MCC_CI_Upper, "Diff. from stopFree Z-score",
         "Diff. from stopFree p-val", "Median Speed kb/sec",
         "Diff. from randScore Z-score", "Diff. from randScore p-val", 
         "Clade")


# Pre-allocate vectors to store the Z-scores and p-values
z_scores_sf <- numeric(nrow(clade_for_reporting))
p_values_sf <- numeric(nrow(clade_for_reporting))
z_scores_rs <- numeric(nrow(clade_for_reporting))
p_values_rs <- numeric(nrow(clade_for_reporting))


# Iterate through the rows of clade_for_reporting
for(i in 1:nrow(clade_for_reporting)){
  # Extract software and clade information for the current row
  software <- clade_for_reporting$Software[i]
  clade <- clade_for_reporting$Clade[i]
  
  # Assign Z-score and p-value to the respective vectors
  z_scores_sf[i] <- roc_comparison_list[[clade]][[software]][["statistic"]][[1]]
  p_values_sf[i] <- roc_comparison_list[[clade]][[software]][["p.value"]]
  
  # Assign Z-score and p-value to the respective vectors
  z_scores_rs[i] <- roc_rand_comparison_list[[clade]][[software]][["statistic"]][[1]]
  p_values_rs[i] <- roc_rand_comparison_list[[clade]][[software]][["p.value"]]
  
}
clade_for_reporting$`Diff. from stopFree Z-score` <- z_scores_sf
clade_for_reporting$`Diff. from stopFree p-val` <- p_values_sf
clade_for_reporting$`Diff. from randScore Z-score` <- z_scores_rs
clade_for_reporting$`Diff. from randScore p-val` <- p_values_rs

View(clade_for_reporting)
write.csv(clade_for_reporting, file = "clade_report.csv")

