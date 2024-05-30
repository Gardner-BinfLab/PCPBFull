# Read the data from the CSV files
citations <- read.csv("data/citations.csv")

citation_software_names <- software_names[software_names != "randScore"]
citation_software_names <- citation_software_names[citation_software_names != "stopFree"]

  # Calculate the average citations per year
current_year <- 2024
citations$Years_Since_Publication <- current_year - citations$Year_Published + 1
citations$Average_Citations_Per_Year <- citations$citations / citations$Years_Since_Publication
citations <- citations %>%
  mutate(Color = software_colors[as.character(Software)])

# Create the plot
ggplot(citations, aes(x = reorder(Software, Average_Citations_Per_Year), y = Average_Citations_Per_Year, fill = Software)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(
    title = "Average citations per year",
    subtitle = "(Google Scholar, 2024)",
    x = "Name",
    y = "Average citations per year"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 30),
    plot.subtitle = element_text(size = 20), # Customize subtitle size here
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    axis.text.x = element_text(size = 20),
    axis.text.y = element_text(size = 20),
    legend.position = "none"
  ) +
  scale_fill_manual(values = software_colors)

