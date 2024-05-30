# Load required libraries
#install.packages("devtools")
#devtools::install_github("G-Thomson/Manu")
#library(devtools)
library(ggplot2)
library(Manu)  # Assuming this library is available for the color palettes


# Read data from the table
incl_data <- read.csv(file="data/inclusion.txt", header=TRUE)

# Define the color palette
pal <- c(get_pal("Kea"), get_pal("Takahe")[1])

# Calculate percentages manually based on the given formula
incl_data$Criteria <- factor(incl_data$Criteria, levels = unique(incl_data$Criteria))

# Create the sideways bar plot using the custom palette
plot <- ggplot(incl_data, aes(x = Criteria, y = Cnt, fill = Criteria)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = sprintf("%.1f%%", Perc)), hjust = -0.2) +
  coord_flip() +
  scale_fill_manual(values = pal) +
  scale_y_continuous(breaks = seq(floor(min(incl_data$Cnt)), 12, by = 1), expand = expansion(mult = c(0.0, 0.1))) +
  labs(title = "Number of included tools
& exclusion reasons", x = "", y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(size = 30),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_text(size = 20),
        axis.text.y = element_text(size = 20),
        legend.position = "none"
        )

# Display the plot
print(plot)






# Bar Plot
pdf(file='barplot-excluded.pdf', width=12, height=10)

incl$Criteria <- factor(incl$Criteria, levels = rev(c("included", sort(setdiff(unique(incl$Criteria), "included")))))
# Create the bar plot

ggplot(incl, aes(x=Criteria, y=Cnt, fill=Criteria)) +
  geom_bar(stat="identity", position="dodge") +
  coord_flip() +
  labs(title="Number of included tools& exclusion reasons", x="", y="") +
  scale_fill_manual(values=pal) +
  scale_y_continuous(breaks = seq(floor(min(incl$Cnt)), 12, by = 1), expand = expansion(mult = c(0.0, 0.1))) +
  geom_text(aes(label=paste(round(100 * Cnt / 36), "%", sep="")), position=position_dodge(width=0.9), hjust=-0.1) +
  theme_minimal() +
  theme(axis.text.x = element_text(hjust=1, size=14),
        axis.text.y = element_text(size=16),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        plot.title = element_text(size=20),
        legend.position = "none")




