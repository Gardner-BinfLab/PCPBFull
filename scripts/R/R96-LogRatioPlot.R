library(tidyverse)
library(dplyr)

dataLogRatioPlot <- data.frame(
  Tool = c("bioseq2seq", "CPC2", "CPPred", "LGC", "PhyloCSF", "PLEK", "RNAcode", "RNAsamba"),
  Sensitivity = c(0.621, 0.665, 0.607, 0.572, 0.776, 0.619, 0.826, 0.597),
  Specificity = c(0.679, 0.623, 0.703, 0.497, 0.752, 0.589, 0.870, 0.672),
  PPV = c(0.393, 0.371, 0.406, 0.275, 0.511, 0.335, 0.680, 0.378),
  MCC = c(0.266, 0.251, 0.277, 0.060, 0.472, 0.181, 0.655, 0.238),
  Self_reported_Sensitivity = c(0.9630, 0.9500, 0.8887, 0.9180, 0.9250, 0.9510, 0.8780, 0.9915),
  Self_reported_Specificity = c(NA, 0.9700, 0.9493, 0.9540, 0.9800, 0.9415, 0.9270, NA),
  Self_reported_PPV = c(0.9600, NA, 0.9456, NA, NA, 0.9985, NA, 0.8891),
  Self_reported_MCC = c(0.9250, NA, 0.8420, NA, NA, NA, NA, 0.8639)
)

calculate_log_ratio <- function(reported, observed) {
  if (is.na(reported) || is.na(observed)) {
    return(NA)
  } else {
    return(log(observed / reported))
  }
}

dataLogRatioPlot  <- dataLogRatioPlot  %>%
  mutate(
    LogRatio_Sensitivity = mapply(calculate_log_ratio, Self_reported_Sensitivity, Sensitivity),
    LogRatio_Specificity = mapply(calculate_log_ratio, Self_reported_Specificity, Specificity),
    LogRatio_PPV = mapply(calculate_log_ratio, Self_reported_PPV, PPV),
    LogRatio_MCC = mapply(calculate_log_ratio, Self_reported_MCC, MCC)
  )

long_data <- pivot_longer(dataLogRatioPlot, cols = starts_with("LogRatio"), names_to = "Metric", values_to = "LogRatio")

long_data$Metric <- sub("LogRatio_", "", long_data$Metric)

long_data$Tool <- factor(long_data$Tool, levels = custom_order)

ggplot(long_data, aes(x = LogRatio, y = Tool, color = Metric)) +
  geom_point(position = position_dodge(width = 0.5), size = 3) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  theme_minimal() + 
  labs(
    title = "Observed vs. reported metrics",
    x = "Log Ratio (Observed / Reported)",
    y = "Tool"
  ) +
  scale_color_manual(values = c(
    "Sensitivity" = "#7CAE00",
    "Specificity" = "#00BFC4",
    "MCC" = "#C77CFF",
    "PPV" = "#FF61CC"
  ), name = "Metric") +
  theme(
    legend_position = "right",
    plot_title = element_text(hjust = 0.5), 
    axis.text.x = element_text(size = 20),
    axis.text.y = element_text(size = 20),
    axis.title.y = element_blank(),
    axis.title.x = element_text(size = 20),
    legend.text = element_text(size = 20),
    plot.title = element_text(size = 30)
  )
