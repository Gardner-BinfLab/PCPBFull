## ---------------------------
##
## Script name: Protein Coding Calculator Benchmark
## Script Plots - Make plots
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

### Box and whisker & Freq plots
for (software in software_names) {
  
  # Load software normalised score data
  sw_data <- bind_rows(combined_tool_results_list[[software]])
  upperY <- freq_setup %>% filter(Software == software) %>% pull(UpperY)
  customBin <- freq_setup %>% filter(Software == software) %>% pull(Bins)
  
  # Load software limit data
  upper_limit <- max(software_normScore_limits[[software]]$Upper)
  lower_limit <- min(software_normScore_limits[[software]]$Lower)
  
  # # Debugging output
  print(paste("Software:", software))
  print(paste("Upper limit:", upper_limit, "Lower limit:", lower_limit))
  # print(head(sw_data))
  
  create_box_whisker_plot(software, sw_data, lower_limit, upper_limit, save_to_file = TRUE)
  create_frequency_plot(software, sw_data, lower_limit, upper_limit, upperY, customBin, save_to_file = TRUE)
}


### ROC curves across all clades
create_combined_roc_plot(combined_roc_df)

### Clade roc curves
process_all_clades_data(roc_data_list, clade_names, software_colors, clade_for_reporting)

### Metrics
create_tool_metrics_beeswarm_plot(long_tool_performance_metrics_df, claimed_metrics_df, auc_upper_df, auc_lower_df)


### DensityPlot
create_density_plot <- function(df, software, clade, threshold) {
  plot_title <- (paste(title = "Density Plot of Scores by", software, "and", clade, sep = " "))
  # Create the density plot with ggplot using updated idioms
  ggplot(df, aes(x = Score, fill = TrueLabels)) + 
    geom_density(alpha = 0.5) +  # Adjust the transparency with alpha
    geom_vline(xintercept = threshold, color = "red", linetype = "dashed", linewidth = 1) + 
    labs(title = plot_title,
         x = "Score",
         y = "Density") +
    scale_fill_manual(values = c("TRUE" = "blue", "FALSE" = "pink")) + 
    theme_minimal()
}

for (software in software_names) {
  for(clade in clade_names){
    sw_data <- combined_tool_results_list[[software]][[clade]]
    sw_data <- sw_data %>% select("Score", "TrueLabels")
    threshold <- roc_metrics_list[[software]][[clade]][["threshold"]]
    densityPlot <- create_density_plot(sw_data, software, clade, threshold)
    print(densityPlot)
  }
}


