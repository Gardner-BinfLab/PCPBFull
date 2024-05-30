# Z-scores for scores
# Import setup
freq_setup <- read_csv_file("setupData/freq_setup.csv")

# Freq name save file suffix
common_word_freq <- "20240513-freq"
common_word_vio <- "20240513-violin"

# Violin plot
create_violin_plot <- function(software, data, lower_limit, upper_limit, save_to_file = FALSE) {
  # Create the violin plot with horizontal orientation
  violin_plot <- ggplot(data = data, aes(y = ControlLabel, x = Zscore, fill = ControlLabel)) +
    geom_violin(trim = TRUE) +
    geom_boxplot(width = 0.1, outlier.shape = NA) +
    coord_flip() +
    facet_wrap(~Clade, scales = "free", ncol = length(unique(data$Clade)), labeller = clade_labeller) +
    labs(title = paste("z score distribution for", software),
         x = "z score",
         y = "") +
    scale_fill_manual(values = c("Coding" = "blue", "Intergenic" = "hotpink", "Shuffled" = "red")) +
    #scale_x_continuous(limits = c(lower_limit+lower_limit*0.5, upper_limit+upper_limit*0.5)) + 
    scale_x_continuous(limits = c(-2, 4.5)) + 
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 24),
      axis.title.x = element_text(size = 20),
      axis.text.x = element_text(angle = 45, size = 20, hjust = 0.85),
      axis.title.y = element_text(size = 20),
      axis.text.y = element_text(size = 20),
      strip.text.x = element_text(size = 20)
    )
  
  if (save_to_file) {
    sanitized_software_name <- gsub(" ", "_", software)
    filename <- paste0(common_word_vio, "-", sanitized_software_name, ".pdf")
    
    pdf(file = filename, width = 8.3, height = 5.8) # A5 size in inches, landscape orientation
    print(violin_plot)
    dev.off()
  } else {
    print(violin_plot)
  }
}

# Create Frequency Plot Function
create_frequency_plot <- function(software, data, upperY, save_to_file = FALSE) {

  # Calculate breaks using min_z and max_z
  breaks <- c(min_z - 1, seq(min_z, max_z, length.out = 800), max_z + 1)
  
  # Initialise the ggplot object for the frequency plot
  freq <- ggplot() +
    labs(title = paste("Frequency distribution for", software),
         x = "z score",
         y = "Relative frequency") +
    theme_minimal() +
    theme(
      legend.position = "top",
      legend.box = "vertical",
      legend.text = element_text(size = 20),
      plot.title = element_text(size = 24),
      axis.title.x = element_text(size = 20),
      axis.title.y = element_text(size = 20),
      axis.text.x = element_text(size = 20),
      axis.text.y = element_text(size = 20),
      legend.key.width = unit(1.2, "cm"),
      legend.key.height = unit(0.5, "cm"),
      legend.title = element_blank()
    ) +
    coord_cartesian(xlim = c(-2, 4), ylim = c(0, upperY))
  #, 
  
  # Loop through each combination of Label and Clade for geom_freqpoly
  for(label in unique(data$ControlLabel)) {
    for(clade in unique(data$Clade)) {
      filtered_data <- dplyr::filter(data, ControlLabel == label, Clade == clade)
      freq <- freq +
        geom_freqpoly(data = filtered_data, aes(x = Zscore, y = ..count../sum(..count..), color = ControlLabel, linetype = Clade),
                      breaks = breaks, size = 0.7, alpha = 0.8)
    }
  }
  
  # Add legend scales
  freq <- freq +
    scale_color_manual(
      name = "Legend",
      values = c("Coding" = "blue", "Intergenic" = "hotpink", "Shuffled" = "red"),
    ) +
    scale_linetype_manual(
      name = "Legend",
      values = c("solid", "longdash", "dotdash"),
      labels = clade_labeller
    )
  
  if (save_to_file) {
    # Replace spaces with underscores in software name for the filename
    sanitized_software_name <- gsub(" ", "_", software)
    filename <- paste0(common_word_freq, "-", sanitized_software_name, ".pdf")
    
    # Specify PDF output
    pdf(file = filename, width = 8.3, height = 5.8) # A5 size in inches, landscape orientation
    
    # Print the plot to the PDF
    print(freq)
    
    # Close the PDF device
    dev.off()
  } else {
    # Just display the plot
    print(freq)
  }
}

software_Zscore_limits <- list()
### Z scores & find nice limits for plots
for (software in software_names) {
  # Filter data for the current software tool
  score_data <- bind_rows(combined_tool_results_list[[software]])
  
  # Update the combined_tool_results_list with normalized scores
  for (clade in names(combined_tool_results_list[[software]])) {
    
    # Extract the relevant subset from score_data
    clade_data <- score_data %>% filter(Clade == clade)
    
    # Separate the scores based on the new labels
    off_scores <- clade_data %>% filter(ControlLabel == "Intergenic") %>% pull(Score)
    shuf_scores <- clade_data %>% filter(ControlLabel == "Shuffled") %>% pull(Score)
    negative_scores <- c(off_scores, shuf_scores)
    
    # Pooled negative mean values
    pooled_neg_mean <- mean(negative_scores)
    pooled_neg_sd <- sd(negative_scores)
    pooled_neg_median <- median(negative_scores)
    
    print(paste(software, clade, "mean:", pooled_neg_mean, "median:", pooled_neg_median, "mean/median:", pooled_neg_mean/pooled_neg_median))
    # Calculate zscore
    clade_data <- clade_data %>% mutate(Zscore = (Score - pooled_neg_mean)/pooled_neg_sd)
    
    # Update the corresponding part of the combined_tool_results_list
    combined_tool_results_list[[software]][[clade]] <- clade_data
    
  }
  
  score_data <- bind_rows(combined_tool_results_list[[software]])
  
  # Calculate the upper and lower bounds for all clades
  x_z_limits <- score_data %>%
    group_by(ControlLabel) %>%
    summarise(
      Qmin = quantile(Zscore,0.025),
      Q1 = quantile(Zscore, 0.25),
      Q3 = quantile(Zscore, 0.75),
      Qmax = quantile(Zscore, 0.975)
    ) %>%
    mutate(
      Lower = pmax(Q1 - 1.5 * (Q3 - Q1), Qmin),
      Upper = pmin(Q3 + 1.5 * (Q3 - Q1), Qmax)
    ) %>% ungroup()
  
  # Add limits to software info
  software_Zscore_limits[[software]] <- x_z_limits
  
  # import freq setup
  range_size <- freq_setup %>% filter(Software == software) %>% pull(Bins)
  
}


# Initialize a vector to store all Z-scores
all_z_scores <- vector("numeric")

# Iterate over each software tool
for (software in names(combined_tool_results_list)) {
  # Iterate over each clade within the software
  for (clade in names(combined_tool_results_list[[software]])) {
    # Extract the Zscore column from each clade's data frame
    clade_data <- combined_tool_results_list[[software]][[clade]]
    if ("Zscore" %in% names(clade_data)) {
      all_z_scores <- c(all_z_scores, clade_data$Zscore)
    }
  }
}

# Calculate the minimum and maximum Z-scores
min_z <- min(all_z_scores, na.rm = TRUE)
max_z <- max(all_z_scores, na.rm = TRUE)

# Print the results
print(paste("Minimum Z-score across all tools and clades:", min_z))
print(paste("Maximum Z-score across all tools and clades:", max_z))

### Box and whisker & Freq plots
for (software in software_names) {
  
  # Load software z score data
  score_data <- bind_rows(combined_tool_results_list[[software]])
  upperY <- freq_setup %>% filter(Software == software) %>% pull(UpperY)
  customBin <- freq_setup %>% filter(Software == software) %>% pull(Bins)
  
  # Load software limit data
  upper_limit <- max(software_Zscore_limits[[software]]$Upper)
  lower_limit <- min(software_Zscore_limits[[software]]$Lower)
  
  # # Debugging output
  print(paste("Software:", software))
  print(paste("Upper limit:", upper_limit, "Lower limit:", lower_limit))
  # print(head(score_data))
  
  create_violin_plot(software, score_data, lower_limit, upper_limit, save_to_file = TRUE)
  # create_box_whisker_plot(software, score_data, lower_limit, upper_limit, save_to_file = TRUE)
  create_frequency_plot(software, score_data, upperY, save_to_file = TRUE)
  #create_density_plot(software, score_data, lower_limit, upper_limit, upperY, customBin, save_to_file = FALSE)
}
