# Load necessary libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# Assuming roc_metrics_list, software_names, and clade_names are already defined

# Initialize an empty data frame to store results
all_metrics <- data.frame()

# Loop through each software and each clade to gather data
for (software in software_names) {
  for (clade in clade_names) {
    if (!is.null(roc_metrics_list[[software]][[clade]])) {
      metrics_df <- roc_metrics_list[[software]][[clade]] %>%
        mutate(software = software, clade = clade) %>%
        select(software, clade, AUC, AUC_CI_Lower, AUC_CI_Upper, 
               sensitivity, se_ci_low, se_ci_up, 
               specificity, sp_ci_low, sp_ci_up, 
               MCC, MCC_CI_Lower, MCC_CI_Upper)
      
      all_metrics <- bind_rows(all_metrics, metrics_df)
    }
  }
}

# Calculate the average AUC for each software
avg_auc <- all_metrics %>%
  group_by(software) %>%
  summarise(mean_auc = mean(AUC, na.rm = TRUE)) %>%
  arrange(desc(mean_auc))

# Reorder the software factor levels based on the average AUC
all_metrics <- all_metrics %>%
  mutate(software = factor(software, levels = avg_auc_combined$software))

# Reshape data for ggplot
metrics_long <- all_metrics %>%
  pivot_longer(cols = c(AUC, sensitivity, specificity, MCC), 
               names_to = "metric", 
               values_to = "value") %>%
  mutate(ci_lower = case_when(
    metric == "AUC" ~ AUC_CI_Lower,
    metric == "sensitivity" ~ se_ci_low,
    metric == "specificity" ~ sp_ci_low,
    metric == "MCC" ~ MCC_CI_Lower
  ),
  ci_upper = case_when(
    metric == "AUC" ~ AUC_CI_Upper,
    metric == "sensitivity" ~ se_ci_up,
    metric == "specificity" ~ sp_ci_up,
    metric == "MCC" ~ MCC_CI_Upper
  )) %>%
  select(-c(AUC_CI_Lower, AUC_CI_Upper, se_ci_low, se_ci_up, sp_ci_low, sp_ci_up, MCC_CI_Lower, MCC_CI_Upper)) %>%
  mutate(metric = factor(metric, levels = c("AUC", "sensitivity", "specificity", "MCC")),
         metric = recode(metric, "sensitivity" = "Sensitivity", "specificity" = "Specificity"))

# Create a named vector for clade conversion
clade_names_map <- setNames(clade_conversion$V2, clade_conversion$V1)
# Plotting
plots <- list()
for (clade_name in clade_names) {
  display_name <- clade_names_map[[clade_name]]
  plot <- ggplot(metrics_long %>% filter(clade == clade_name), aes(x = software, y = value, color = metric, group = metric)) +
    geom_point(position = position_dodge(width = 0.50)) +
    geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), 
                  position = position_dodge(width = 0.50), 
                  width = 0.2) +
    theme_minimal() +
    labs(title = paste("Metrics for", display_name),
         x = "Software",
         y = "Metric Value",
         color = "Metric") +
    scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
    theme(axis.text.x = element_text(size = 18, angle = 45, hjust = 1),
            axis.text.y = element_text(size = 18),
            axis.title.y = element_blank(),
            axis.title.x = element_blank(),
            legend.text = element_text(size = 18),
          legend.title = element_blank(),
            plot.title = element_text(size = 24)) +
    ylim(-0.18, 1)
  
  plots[[clade_name]] <- plot
}

# Display the plots
plots[["fungiGroup"]]
plots[["catGroup"]]
plots[["melonGroup"]]

#combined

# Initialize an empty data frame to store results
combined_metrics <- data.frame()

# Loop through each software to gather data
for (software in software_names) {
  if (!is.null(combined_roc_metrics_list[[software]])) {
    metrics_df <- combined_roc_metrics_list[[software]] %>%
      mutate(software = software) %>%
      select(software, AUC, auc_ci_low, auc_ci_up, 
             Sensitivity, se_ci_low, se_ci_up, 
             Specificity, sp_ci_low, sp_ci_up, 
             MCC, mcc_ci_low, mcc_ci_up)
    
    combined_metrics <- bind_rows(combined_metrics, metrics_df)
  }
}

# Calculate the average AUC for each software
avg_auc_combined <- combined_metrics %>%
  group_by(software) %>%
  summarise(mean_auc = mean(AUC, na.rm = TRUE)) %>%
  arrange(desc(mean_auc))

# Reorder the software factor levels based on the average AUC
combined_metrics <- combined_metrics %>%
  mutate(software = factor(software, levels = avg_auc_combined$software))

# Reshape data for ggplot
metrics_long_combined <- combined_metrics %>%
  pivot_longer(cols = c(AUC, Sensitivity, Specificity, MCC), 
               names_to = "metric", 
               values_to = "value") %>%
  mutate(ci_lower = case_when(
    metric == "AUC" ~ auc_ci_low,
    metric == "Sensitivity" ~ se_ci_low,
    metric == "Specificity" ~ sp_ci_low,
    metric == "MCC" ~ mcc_ci_low
  ),
  ci_upper = case_when(
    metric == "AUC" ~ auc_ci_up,
    metric == "Sensitivity" ~ se_ci_up,
    metric == "Specificity" ~ sp_ci_up,
    metric == "MCC" ~ mcc_ci_up
  )) %>%
  select(-c(auc_ci_low, auc_ci_up, se_ci_low, se_ci_up, sp_ci_low, sp_ci_up, mcc_ci_low, mcc_ci_up)) %>%
  mutate(metric = factor(metric, levels = c("AUC", "Sensitivity", "Specificity", "MCC")))

# Plotting
plot_combined <- ggplot(metrics_long_combined, aes(x = software, y = value, color = metric, group = metric)) +
  geom_point(position = position_dodge(width = 0.50)) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), 
                position = position_dodge(width = 0.50), 
                width = 0.2) +
  theme_minimal() +
  labs(title = "Metrics for all clades",
       x = "Software",
       y = "Metric Value",
       color = "Metric") +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
  theme(axis.text.x = element_text(size = 18, angle = 45, hjust = 1),
        axis.text.y = element_text(size = 18),
        axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        legend.text = element_text(size = 18),
        legend.title = element_blank(),
        plot.title = element_text(size = 24)) +
  ylim(-0.18, 1)

# Display the plot
print(plot_combined)

