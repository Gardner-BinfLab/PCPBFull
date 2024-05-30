
timing_software_names <- software_names[software_names != "randScore"]

# Define the column names
column_names <- c("Name", "realTime", "userTime", "sysTime", "lengthInNucleotides")

# Initialize an empty data frame to store combined data
combined_data <- data.frame()

# Loop over software names to read all files
for (tool in timing_software_names) {
  file_name <- paste("data/timing/", paste(tool, "catGroup", "timing_timing_with_sizes.txt", sep = "_"), sep = "")
  # Read the data from the file without a header
  data <- read_csv(file_name, col_names = column_names)
  # Add a column for the tool to the data frame
  data$Software <- tool
  # Calculate KB per second for each row
  #data$KB_per_second <- (data$lengthInNucleotides / 1000) / data$realTime
  
  # Combine the data frame with the rest
  combined_data <- bind_rows(combined_data, data)
}

# Calculate the mean time per tool for ordering
means <- combined_data %>%
  group_by(Software) %>%
  summarize(mean_seconds = mean(realTime, na.rm = TRUE)) %>%
  ungroup()

# Join the means to the combined_data
combined_data <- combined_data %>%
  left_join(means, by = "Software")

# Reorder Software based on the mean seconds
combined_data <- combined_data %>%
  mutate(Software = reorder(Software, mean_seconds))


# Ensure that `means` is ordered by mean seconds
means <- means %>%
  arrange(mean_seconds)

#use the ordered Software names from `means` to set the levels of the Software factor
combined_data$Software <- factor(combined_data$Software, levels = means$Software)

# Add color details
combined_data <- combined_data %>%
  mutate(Color = software_colors[as.character(Software)])

# Update the filtered_data with the correct Software factor levels
filtered_data <- combined_data %>%
  filter(realTime > 0, lengthInNucleotides > 0)

filtered_data$Software <- factor(filtered_data$Software, levels = means$Software)

#custom label
custom_format <- function(x) {
  sapply(x, function(x) {
    if (is.na(x)) {
      return(NA)  # Return NA if the value is NA
    } else if (x == floor(x)) {
      return(as.character(as.integer(x)))  # Format as integer if it's an integer
    } else {
      return(format(x, nsmall = 2))  # Keep two decimal places otherwise
    }
  })
}

# Horizontal dot plot with mean lines for seconds per sequence
ggplot(combined_data, aes(x = Software, y = realTime)) +
  geom_point(aes(color = Software), position = position_jitter(width = 0.2, height = 0), size = 1, alpha = 0.7) +
  stat_summary(aes(group = Software), fun = mean, geom = "crossbar", width = 0.6, color = "black", fatten = 2) +
  coord_flip() +
  labs(x = "Software", y = "Time per sequence (s)", title = "Execution time") +
  theme_minimal() +
  theme(
    legend.position = "none",
    #plot.margin = margin(t = 5, r = 10, b = 5, l = 5, unit = "mm"),
    plot.title = element_text(size = 30),
    axis.title.y = element_blank(),
    axis.title.x = element_text(size = 20),
    axis.text.x = element_text(angle = 45, size = 20),
    axis.text.y = element_text(size = 20),
    legend.title = element_blank(),
    legend.text = element_blank()
  ) +
  scale_y_log10(labels = custom_format) +
  scale_color_manual(values = software_colors)



# Calculate linear models and create equations for each tool group
equations_df <- filtered_data %>%
  group_by(Software) %>%
  do(model = lm(log10(realTime) ~ log10(lengthInNucleotides), data = .)) %>%
  rowwise() %>%
  mutate(equation = paste(Software, ": y =", round(coef(model)[2], 2), "x +", round(coef(model)[1], 2))) %>%
  select(Software, equation) %>%
  ungroup()

# Merge the equations back to the filtered_data
filtered_data <- filtered_data %>%
  left_join(equations_df, by = "Software")

# New metric of type grouping
filtered_data <- filtered_data %>% mutate(Type = case_when(
  startsWith(Name, "Off") ~ "Intergenic",
  startsWith(Name, "Shuf") ~ "Shuffled",
  TRUE ~ "Coding"))

filtered_data_check<- filtered_data %>%
  mutate(logLen = log10(lengthInNucleotides)) %>% 
  mutate(logTime = log10(realTime))

# Plot of log length in nucleotides over log of real time
p <- ggplot(filtered_data, aes(x = log10(lengthInNucleotides), y = log10(realTime), color = Software)) +
  geom_point(aes(shape = Type), size = 3, alpha = 0.5) +
  geom_smooth(method = "lm", se = FALSE) +
  theme_minimal() +
  theme(plot.title = element_text(size = 30),
        axis.title.x = element_text(size = 20),
        axis.title.y = element_text(size = 20),
        axis.text.x = element_text(size = 20),
        axis.text.y = element_text(size = 20),
        legend.title = element_blank(),
        legend.text = element_text(size = 20)
        ) +
  labs(
    x = "Log of length in nucleotides", 
    y = "Log of real time (s)", 
    title = "Execution time vs length", 
    color = "Tool",
    shape = "Type"  
  ) +
  scale_color_manual(values = software_colors, guide = guide_legend(reverse = TRUE)) +
  scale_shape_manual(values = c("Intergenic" = 3, "Shuffled" = 2, "Coding" = 1))
# Print the plot
print(p)
