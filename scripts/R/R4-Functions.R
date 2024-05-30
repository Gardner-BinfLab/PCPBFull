## ---------------------------
##
## Script name: Protein Coding Calculator Benchmark
## Script Four - Functions
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

### Data manipulation ---

# Function to adjust the Name column
adjust_name <- function(name, prefixes) {
  prefix_found <- any(sapply(prefixes, function(prefix) grepl(paste0("^", prefix), name)))
  parts <- unlist(strsplit(name, "_"))
  if (prefix_found) {
    # Keep the first 5 parts if name starts with a known prefix
    return(paste(parts[1:5], collapse = "_"))
  } else {
    # Otherwise, keep the first 4 parts
    return(paste(parts[1:4], collapse = "_"))
  }
}

# Assume seq_data is your sequence length dataframe for a given clade
expand_seq_data <- function(seq_data, prefixes) {
  base_data <- seq_data
  # Create copies of seq_data for each prefix and modify the Name column
  for (prefix in prefixes) {
    prefixed_data <- seq_data
    prefixed_data$Name <- paste(prefix, seq_data$Name, sep = "_")
    base_data <- rbind(base_data, prefixed_data)  # Combine with original data
  }
  return(base_data)
}

# Function to extract and preprocess data for a given software and clade
process_clade_results <- function(tool_results, clade) {
  clade_results <- tool_results[tool_results$Clade == clade, ]
  true_count <- sum(clade_results$TrueLabels == TRUE, na.rm = TRUE)
  false_count <- sum(clade_results$TrueLabels == FALSE, na.rm = TRUE)
  
  # Return a list containing the results and counts
  list(clade_results = clade_results, 
       true_count = true_count, 
       false_count = false_count)
}

# Function to create ROC data frame per clade
create_roc_data <- function(clade_results, software, clade) {
  if(software == "CPPred"){
    roc_object <- roc(direction = ">", clade_results$TrueLabels, clade_results$Score)
  }else{
    roc_object <- roc(direction = "<", clade_results$TrueLabels, clade_results$Score)
  }
  # Return ROC data and the ROC object
  list(roc_data = data.frame(
    FPR = 1 - as.numeric(roc_object[['specificities']]),
    TPR = as.numeric(roc_object[['sensitivities']]),
    Software = software,
    Clade = clade
  ),
  roc_object = roc_object)
}

# Function to create ROC data frame per software
create_tool_roc_data <- function(combined_tool_results, software) {
  if(software == "CPPred"){
    roc_object <- roc(direction = ">", combined_tool_results$TrueLabels, combined_tool_results$Score)
  }else{
    roc_object <- roc(direction = "<", combined_tool_results$TrueLabels, combined_tool_results$Score)
  }
  
  # Return ROC data and the ROC object
  list(roc_data = data.frame(
    FPR = 1 - as.numeric(roc_object[['specificities']]),
    TPR = as.numeric(roc_object[['sensitivities']]),
    Software = software
  ),
  roc_object = roc_object)
}

# Matthews Correlation Coefficient (MCC)
calculate_mcc <- function(tp, tn, fp, fn) {
  numerator <- (tp * tn) - (fp * fn)
  denominator <- sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn))
  if (denominator == 0) return(0)  # Avoid division by zero
  return(numerator / denominator)
}

# F1 Score
calculate_f1 <- function(tp, fp, fn) {
  precision <- tp / (tp + fp)
  recall <- tp / (tp + fn)
  if ((precision + recall) == 0) return(0)  # Avoid division by zero
  return(2 * ((precision * recall) / (precision + recall)))
}


# Labels for controls
label_from_name <- function(name, seq_prefixes) {
  if (startsWith(name, "Shuf")) {
    return("Shuffled")
  } else if (startsWith(name, "Off")) {
    return("Intergenic")
  } else {
    return("Coding")
  }
}

### Plot functions ----

# Create Box and Whisker Plot Function
# (Warning message about removal of non-finite values is due to upper and lower limits. It just removes them from plotting)
create_box_whisker_plot <- function(software, data, lower_limit, upper_limit, save_to_file = FALSE) {
  # Create the box and whisker plot with horizontal orientation
  bw_plot <- ggplot(data = data, aes(y = ControlLabel, x = Zscore, fill = ControlLabel)) +
    geom_boxplot(outlier.alpha = 0.3, notch = TRUE) +
    #geom_boxplot(outlier.shape = NA) +
    coord_flip() +
    facet_wrap(~Clade, scales = "free", ncol = length(unique(data$Clade)), labeller = clade_labeller) +
    labs(title = paste("Z-score distribution for", software),
         x = "Z Score difference from
log negative controls",
         y = "") +
    scale_fill_manual(values = c("Coding" = "blue", "Intergenic" = "hotpink", "Shuffled" = "red")) +
    scale_x_continuous(limits = c(lower_limit+lower_limit*0.5, upper_limit+upper_limit*0.5)) + 
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 24),
      axis.title.x = element_text(size = 22),
      axis.text.x = element_text(angle = 45, size = 22, hjust = 0.85),
      axis.title.y = element_text(size = 22),
      axis.text.y = element_text(size = 22),
      strip.text.x = element_text(size = 22)
    )
  
  if (save_to_file) {
    # Replace spaces with underscores in software name for the filename
    sanitized_software_name <- gsub(" ", "_", software)
    filename <- paste0(common_word_baw, "-", sanitized_software_name, ".pdf")
    
    # Specify PDF output
    pdf(file = filename, width = 8.3, height = 5.8) # A5 size in inches, landscape orientation
    
    # Print the plot to the PDF
    print(bw_plot)
    
    # Close the PDF device
    dev.off()
  } else {
    # Just display the plot
    print(bw_plot)
  }
}

# Violin plot
create_violin_plot <- function(software, data, lower_limit, upper_limit, save_to_file = FALSE) {
  # Create the violin plot with horizontal orientation
  violin_plot <- ggplot(data = data, aes(y = ControlLabel, x = Zscore, fill = ControlLabel)) +
    geom_violin(trim = TRUE) +
    geom_boxplot(width = 0.1, outlier.shape = NA) +
    coord_flip() +
    facet_wrap(~Clade, scales = "free", ncol = length(unique(data$Clade)), labeller = clade_labeller) +
    labs(title = paste("Z-score distribution for", software),
         x = "Z-score difference from
negative controls",
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

# Update verdicts
# Function to update the Verdict based on Label
update_verdict <- function(df) {
  if("Label" %in% colnames(df)) {
    df$Verdict <- ifelse(df$Label %in% c("coding", "Coding"), "coding",
                         ifelse(df$Label %in% c("noncoding", "non-coding", "Non-coding", "No"), "noncoding", NA))
    df <- subset(df, select = -c(Label)) # Remove the "Label" column
    }else{
    df$Verdict <- NA
  }
  return(df)
}

# Create Frequency Plot Function
create_frequency_plot <- function(software, data, lower_limit, upper_limit, upperY, customBins, save_to_file = FALSE) {
  # Initialise the ggplot object for the frequency plot
  freq <- ggplot() +
    labs(title = paste("Frequency distribution for", software),
         x = "Z-score",
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
    coord_cartesian(xlim = c(-2, 4.5), ylim = c(0, upperY))  # Use IQR-based limits
  
  # Loop through each combination of Label and Clade for geom_freqpoly
  if(software == "randScore"){
    for(label in unique(data$ControlLabel)) {
      for(clade in unique(data$Clade)) {
        filtered_data <- dplyr::filter(data, ControlLabel == label, Clade == clade)
        freq <- freq +
          geom_freqpoly(data = filtered_data, aes(x = Zscore, y = ..count../sum(..count..), color = ControlLabel, linetype = Clade),
                        bins = 25, linewidth = 0.7, alpha = 0.8)
      }
    }
  }else{
    for(label in unique(data$ControlLabel)) {
      for(clade in unique(data$Clade)) {
        filtered_data <- dplyr::filter(data, ControlLabel == label, Clade == clade)
        freq <- freq +
          geom_freqpoly(data = filtered_data, aes(x = Zscore, y = ..count../sum(..count..), color = ControlLabel, linetype = Clade),
                        bins = 150, linewidth = 0.7, alpha = 0.8)
      }
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

# plot ROC for average
create_combined_roc_plot <- function(combined_roc) {
  # Ensure that 'Software' in 'combined_tool_auc' is ordered by 'AUC'
  ordered_software <- combined_tool_auc %>% 
    arrange(desc(AUC)) %>% 
    pull(Software)
  
  # Use the ordered 'Software' to set levels in 'combined_roc_with_AUC'
  combined_roc$Software <- factor(combined_roc$Software, 
                                           levels = ordered_software)
  
  ggplot(combined_roc, aes(x = FPR, y = TPR, color = Software, group = Software)) +
  geom_line(size = 1) +
  labs(title = "ROC curves across all clades",
       x = "1 - Specificity",
       y = "Sensitivity") +
  theme_minimal() +
  guides(color = guide_legend(title = NULL)) +
  scale_alpha_continuous(range = c(0.15, 0.9)) +
  scale_color_manual(values = software_colors) +
  theme(legend.position = c(0.865, 0.375),
        legend.text = element_text(size = 20),
        plot.title = element_text(size = 30),
        axis.title.x = element_text(size = 20),
        axis.title.y = element_text(size = 20),
        axis.text.x = element_text(size = 20),
        axis.text.y = element_text(size = 20),
        legend.title = element_blank()
  )
}


# Function to combine data from all software tools for a specific clade
combine_clade_data <- function(roc_data_list, clade, clade_for_reporting) {
  combined_data <- do.call(rbind, lapply(names(roc_data_list), function(software) {
    clade_data <- roc_data_list[[software]][[clade]]
    if (!is.null(clade_data)) {
      clade_data$Software <- software  # Add a column to identify the software
      # Look up AUC for this software and clade
      auc_info <- clade_for_reporting %>% 
        filter(Clade == clade, Software == software) %>%
        select(AUC) %>%
        pull()
      if(length(auc_info) > 0) {
        clade_data$AUC <- auc_info[1]  # Assuming one AUC value per software-clade pair
      } else {
        clade_data$AUC <- NA  # In case there's no AUC info
      }
      return(clade_data)
    } else {
      return(NULL)
    }
  }))
  
  # Remove rows with NA AUC (if any)
  combined_data <- combined_data[!is.na(combined_data$AUC), ]
  
  # Order the Software factor based on AUC
  combined_data <- combined_data %>%
    arrange(desc(AUC)) %>%
    mutate(Software = factor(Software, levels = unique(Software)))
  
  return(combined_data)
}

# unction to create and print a ROC plot for a combined data frame of a specific clade
create_clade_roc_plot <- function(combined_clade_data, clade, software_colors) {
  
  descriptive_name <- filter(clade_conversion, V1 == clade) %>% pull(V2)
  
  # If no match is found, use the original clade name
  if (length(descriptive_name) == 0) {
    descriptive_name <- clade
  }
  
  cladeTitle = paste("ROC curves for", descriptive_name)
  ggplot_object <- ggplot(combined_clade_data, aes(x = FPR, y = TPR, color = Software, group = Software)) +
    geom_line(size = 1) +
    labs(title = cladeTitle,
         x = "1 - Specificity",
         y = "Sensitivity") +
    theme_minimal() +
    guides(color = guide_legend(title = "Software")) +
    scale_color_manual(values = software_colors) +
    theme(legend.position = "right",
          plot.title = element_text(size = 26),
          axis.title = element_text(size = 20),
          axis.text = element_text(size = 16),
          legend.text = element_text(size = 24))
  
  print(ggplot_object)
}

# Main function to process data and create ROC plots for each clade
process_all_clades_data <- function(roc_data_list, clades, software_colors, clade_for_reporting) {
  for (clade in clades) {
    combined_clade_data <- combine_clade_data(roc_data_list, clade, clade_for_reporting)
    if (nrow(combined_clade_data) > 0) {  # Ensure there is data to plot
      create_clade_roc_plot(combined_clade_data, clade, software_colors)
    }
  }
}

# Plot for metric beeswarm
create_tool_metrics_beeswarm_plot <- function(performance_metrics, claimed_metrics, AUC_upper, AUC_lower){
ggplot(performance_metrics, aes(x = Software, y = Value, color = Metric)) +
  geom_beeswarm(cex = 0.5, dodge.width = 0.7, size = 2, alpha = 0.7) +
  #stat_summary(aes(group = Metric), fun = mean, geom = "crossbar", width = 0.8, position = position_dodge(0.7)) +
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
  ylim(0, 1.0) +
  geom_beeswarm(data = claimed_metrics, shape = 'x', dodge.width = 0.7, size = 5, alpha = 0.7) +
  geom_beeswarm(data = AUC_upper, shape = '-', dodge.width = 0.7, size = 5, alpha = 0.7) +
  geom_beeswarm(data = AUC_lower, shape = '-', dodge.width = 0.7, size = 5, alpha = 0.7)
}


