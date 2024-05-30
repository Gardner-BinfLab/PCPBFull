# Function to convert roc_metrics_list to a dataframe
convert_roc_list_to_df <- function(roc_list, metrics) {
  do.call(rbind, lapply(names(roc_list), function(software) {
    do.call(rbind, lapply(names(roc_list[[software]]), function(group) {
      sapply(metrics, function(metric) {
        data.frame(
          Software = software,
          Group = group,
          Metric = metric,
          Value = unlist(roc_list[[software]][[group]][metric]),
          stringsAsFactors = FALSE
        )
      }, simplify = FALSE)
    }))
  })) %>% bind_rows()
}

# Define the metrics of interest
metrics_of_interest <- c("AUC", "sensitivity", "specificity", "MCC")

# Convert the list to a dataframe
metrics_data <- convert_roc_list_to_df(roc_metrics_list, metrics_of_interest)

# Rename and order
metrics_data <- metrics_data %>%
  mutate(Metric = recode(Metric,
                         'sensitivity' = 'Sensitivity',
                         'specificity' = 'Specificity')) %>% 
  mutate(
    Software = factor(Software, levels = custom_order),
    Metric = factor(Metric, levels = c("AUC", "Sensitivity", "Specificity", "MCC"))
  )

# Reorder
claimed_metrics_df <- claimed_metrics_df %>%
  mutate(
    Software = factor(Software, levels = custom_order),
    Metric = factor(Metric, levels = c("AUC", "Sensitivity", "Specificity", "MCC"))
  )

# Calculate average positions for actual metrics for arrow starting points
avg_metrics_data <- long_tool_performance_metrics_df %>% 
  group_by(Software, Metric) %>%
  select(Software,Metric,Value) %>% 
  summarize(Value = mean(Value), .groups = 'drop')


create_tool_metrics_plot_with_arrows <- function(metrics_data, claimed_metrics, avg_metrics_data) {
  # Base plot
  p <- ggplot() +
    geom_beeswarm(data = metrics_data, aes(x = Software, y = Value, color = Metric),
                  cex = 0.5, dodge.width = 0.7, size = 2, alpha = 0.7, priority = 'density') +
    geom_beeswarm(data = claimed_metrics, aes(x = Software, y = Value, shape = Metric),
                  shape = 'x', colour ='black', dodge.width = 0.7, size = 5, alpha = 0.7) +
    geom_beeswarm(data = avg_metrics_data, aes(x = Software, y = Value, color = Metric),
                  shape = "-", dodge.width = 0.7, size = 10, alpha = 0.7) +
    labs(title = "Tool Performance",
         x = "Software",
         y = "Performance") +
    theme_minimal() +
    theme(
      legend.position = "top",
      plot.title = element_text(size = 24),
      axis.title.x = element_blank(),
      axis.title.y = element_text(size = 18),
      axis.text.x = element_text(angle = 45, size = 18),
      axis.text.y = element_text(size = 18),
      legend.title = element_blank(),
      legend.text = element_text(size = 18)
    ) +
    ylim(0, 1.0)

  # Offset for arrows based on metric
  metric_offsets <- c(AUC = -0.16, Sensitivity = -0.08, Specificity = 0.08, MCC = 0.24) 
  
  # Merge this with claimed metrics for arrow ending points
  arrow_data <- merge(claimed_metrics, avg_metrics_data, by = c("Software", "Metric"))
  arrow_data <- arrow_data %>% filter(Value.x != -1) %>%
    mutate(
      StartX = as.numeric(Software) + ifelse(Metric %in% names(metric_offsets), metric_offsets[Metric], 0),
      EndX = as.numeric(Software) + ifelse(Metric %in% names(metric_offsets), metric_offsets[Metric], 0)
    )
  # Add adjusted arrows to the plot
  p <- p + geom_segment(data = arrow_data, aes(x = StartX, xend = EndX, y = Value.x, yend = Value.y),
                        arrow = arrow(length = unit(0.3, "cm")), color = "black")
  
  return(p)
}



#
create_tool_metrics_plot_with_arrows(metrics_data, claimed_metrics_df, avg_metrics_data)



auc_means <- tibble()
create_tool_metrics_plot_with_arrows <- function(metrics_data, claimed_metrics, avg_metrics_data) {
  # Calculate mean AUC for each software and order software based on this
  auc_means <- long_tool_performance_metrics_df %>% 
    filter(Metric == "AUC") %>%
    group_by(Software) %>%
    summarize(MeanAUC = mean(Value, na.rm = TRUE)) %>%
    arrange(desc(MeanAUC)) %>%
    pull(Software)
  
  # Set this order in the factor levels for each dataset
  metrics_data$Software <- factor(metrics_data$Software, levels = auc_means)
  claimed_metrics$Software <- factor(claimed_metrics$Software, levels = auc_means)
  avg_metrics_data$Software <- factor(avg_metrics_data$Software, levels = auc_means)
  
  # Define offsets for each metric
  metric_offsets <- c(AUC = -0.24, Sensitivity = -0.08, Specificity = 0.08, MCC = 0.24)
  
  # Apply offsets to datasets
  apply_offsets <- function(df) {
    df$OffsetX <- as.numeric(df$Software) + 
      sapply(df$Metric, function(m) metric_offsets[m])
    return(df)
  }
  
  # Apply offsets to each dataset
  metrics_data <- apply_offsets(metrics_data)
  claimed_metrics <- apply_offsets(claimed_metrics)
  avg_metrics_data <- apply_offsets(avg_metrics_data)
  
  # Prepare arrow data with applied offsets
  arrow_data <- merge(claimed_metrics, avg_metrics_data, by = c("Software", "Metric"))
  arrow_data <- arrow_data %>% filter(Value.x != -1) %>%
    mutate(
      StartX = OffsetX.x,
      EndX = OffsetX.y
    )
  
  # Base plot
  p <- ggplot() +
    geom_point(data = metrics_data, aes(x = OffsetX, y = Value, color = Metric), size = 2, alpha = 0.7) +
    geom_point(data = claimed_metrics, aes(x = OffsetX, y = Value), shape = "x", color = 'black', size = 5, alpha = 0.7) +
    geom_point(data = avg_metrics_data, aes(x = OffsetX, y = Value, color = Metric), shape = "-", size = 10, alpha = 0.7) +
    geom_segment(data = arrow_data, aes(x = StartX, xend = EndX, y = Value.x, yend = Value.y), 
                 arrow = arrow(length = unit(0.3, "cm")), color = "black") +
    labs(title = "Tool performance", x = "Software", y = "Performance") +
    theme_minimal() +
    theme(
      legend.position = "top",
      plot.title = element_text(size = 30),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 20),
      axis.text.y = element_text(size = 20),
      legend.title = element_blank(),
      legend.text = element_text(size = 20)
    ) +
    ylim(0, 1.0) +
    scale_x_continuous(breaks = 1:length(auc_means), labels = auc_means)  # Updated to maintain AUC order
  
  return(p)
}

create_tool_metrics_plot_with_arrows(metrics_data, claimed_metrics_df, avg_metrics_data)
