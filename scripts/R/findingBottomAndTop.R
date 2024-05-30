# Getting top and bottom 10 scoring seqs
normScore_list_adj <- list()
# Loop through each software
for (software in software_names) {
  # Initialize an empty data frame for this software
  software_wide <- data.frame(Name=character(), stringsAsFactors=FALSE)
  
  # Loop through each clade within the software
  for (clade in clade_names) {
    # Extract the relevant columns (Name and normScore)
    clade_data <- combined_tool_results_list[[software]][[clade]][, c("Name", "normScore", "Length")]
    
    # Add a new column for the clade name
    clade_data$Clade <- clade
    
    # Rename the normScore column to software name
    colnames(clade_data)[2] <- software
    
    # If the software-wide data frame is empty, copy the clade data directly
    if (nrow(software_wide) == 0) {
      software_wide <- clade_data
    } else {
      # Otherwise, merge with existing data on Name
      software_wide <- rbind(software_wide, clade_data)
    }
  }
  
  # Add the wide-format data for this software to the list
  normScore_list_adj[[software]] <- software_wide
}

# Extract unique Name and Clade pairs from all tools
name_clade_triplets <- do.call(rbind, lapply(normScore_list_adj, function(df) df[, c("Name", "Clade", "Length")]))
unique_name_clade_triplets <- unique(name_clade_triplets)

# Start with a data frame that contains unique Names and their associated Clades
normScore_adj <- unique_name_clade_triplets

# Loop through each software tool and join its data with the normScore_adj
for (software in names(normScore_list_adj)) {
  # Prepare the software-specific data frame; ensure it has Name, Clade, and the normScore
  software_df <- select(normScore_list_adj[[software]], Name, Clade, Length, matches(software))
  
  # Join with the final wide-format data frame
  normScore_adj <- full_join(normScore_adj, software_df, by = c("Name", "Clade", "Length"))
}


# inverse CPPred, since it's backwards scoring
normScore_adj$CPPred <- normScore_adj$CPPred * -1

# Add a combined 'normScore' field that contains the sum of all 'normScores' for each sample 'Name'
normScore_adj <- normScore_adj %>%
  rowwise() %>%
  mutate(Combined_normScore = sum(c_across(c(-random, -Name, -Clade, -Length)), na.rm = TRUE)) %>%
  ungroup()


# initialsise lists
top5 <- list()

for(clade in clade_names){
# Take top 10
  top5_sequences <- normScore_adj %>%
  filter(Clade == clade, Length <= 650, Length >= 250) %>% 
  arrange(desc(Combined_normScore)) %>%
  slice_head(n = 5) %>%
  select(Name) %>%
  pull()
  
  # Prepend the path to each sequence name
  if(clade == "fungiGroup"){
    top5[[clade]] <- paste("data/resultingSeqs/fungi/GCF_016861865.1/Exons/", top5_sequences, "_Aspergillus_puulaauensis.fa", sep = "")
  } else if(clade == "melonGroup"){
    top5[[clade]] <- paste("data/resultingSeqs/plantae/GCF_025177605.1/Exons/", top5_sequences, "_Cucumis_melo.fa", sep = "")
  } else if(clade == "catGroup"){
    top5[[clade]] <- paste("data/resultingSeqs/animalia/GCF_018350175.1/Exons/", top5_sequences, "_Felis_catus.fa", sep = "")
  } 
}

#  combine
top15_seq <- NULL

for(clade in clade_names){
  top15_seq <- c(top15_seq, top5[[clade]])
}

# Save to file
write(top15_seq, file = "../../results/misc/top15.txt")


