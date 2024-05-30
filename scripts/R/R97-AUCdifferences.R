### Diff from stopFree 
# Reorder 'Software' based on 'Diff. from stopFree Z-score'
for_reporting$Software <- factor(for_reporting$Software, levels = for_reporting$Software[order(for_reporting$`Diff. from stopFree Z-score`, decreasing = TRUE)])

# 2. Plotting
ggplot(data = for_reporting, aes(x = Software, y = `Diff. from stopFree Z-score`, fill = Software)) + 
 geom_bar(stat = "identity") +
 scale_fill_manual(values = software_colors, guide = FALSE) + 
 geom_text(aes(label = ifelse(`Diff. from stopFree Z-score` != 0, 
                              formatC(`Diff. from stopFree p-val`, format = "e", digits = 1), 
                              ""),  # Exclude label for Z-score of 0
               y = ifelse(`Diff. from stopFree Z-score` > 0, 
                          -abs(min(for_reporting$`Diff. from stopFree Z-score`)*0.05), 
                          abs(min(for_reporting$`Diff. from stopFree Z-score`)*0.05)),
               hjust = ifelse(`Diff. from stopFree Z-score` > 0, 0.9, -0.1)),  # Adjust horizontal placement
           color = "black", size = 4.5, vjust = ifelse(for_reporting$`Diff. from stopFree Z-score` > 0, 2, -2), angle = 45) + 
 theme_minimal(base_size = 24) +
 theme(axis.text.x = element_text(size = 20, angle = 45, vjust = 1.1, hjust=1), 
       axis.title.x = element_blank(), 
       axis.title.y = element_text(size = 20),
       axis.text.y = element_text(size = 20),
       plot.title = element_text(size = 30),
       legend.position = "none") +
 labs(
   title = "AUC difference from stopFree",
   x = "",
   y = "z score"
 )
 
 
# Reorder 'Software' based on 'Diff. from randScore Z-score'
for_reporting$Software <- factor(for_reporting$Software, levels = for_reporting$Software[order(for_reporting$`Diff. from randScore Z-score`, decreasing = TRUE)])

# 2. Plotting
ggplot(data = for_reporting, aes(x = Software, y = `Diff. from randScore Z-score`, fill = Software)) + 
  geom_bar(stat = "identity") +
  scale_fill_manual(values = software_colors, guide = FALSE) + 
  geom_text(aes(label = ifelse(`Diff. from randScore Z-score` != 0, 
                               formatC(`Diff. from randScore p-val`,
                                       format = "e",
                                       digits = 2
                                       ),
                               ""
                               ),  # Exclude label for Z-score of 0
                y = ifelse(`Diff. from randScore Z-score` > 40, 
                           35,
                           `Diff. from randScore Z-score` + abs(min(for_reporting$`Diff. from randScore Z-score`)+ 1 * 4)),  # Just above the bar for others
                hjust = ifelse(`Diff. from randScore Z-score` > 0, 0.5, -0.5)),  # Adjust horizontal placement
                color = "black", size = 3, angle = 45) +  # Optional adjustments for appearance
  theme_minimal(base_size = 20) +
  theme(axis.text.x = element_text(size = 20, angle = 45, vjust = 1, hjust=1), 
        axis.title.x = element_blank(), 
        axis.title.y = element_text(),
        plot.title = element_text(size = 30),
        legend.position = "none") +
  labs(
    title = "AUC difference from randScore",
    x = "",
    y = "z score"
  )
