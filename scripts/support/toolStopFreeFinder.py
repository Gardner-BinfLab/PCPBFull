import sys
# stopFree - identifies the longest continuous segment of a DNA sequence
# that doesn't contain any "stop signals," considering both the original
# and its mirror-image counterpart.

# Function to calculate the reverse complement of a DNA sequence
def reverse_complement(sequence):
    # Define the complement mapping for DNA bases
    complement = {'A': 'T', 'C': 'G', 'G': 'C', 'T': 'A'}
    # Generate the reverse complement sequence
    return ''.join([complement[base] for base in reversed(sequence)])

# Function to find the longest non-stop region in a DNA sequence
def longest_non_stop_region(fasta_file_path):
    # Read the fasta file
    with open(fasta_file_path, 'r') as input_file:
        lines_in_file = input_file.readlines()

    # Extract sequence ID
    sequence_id = lines_in_file[0].strip().split()[0][1:]
    
    # Extract and concatenate sequence data, converting to uppercase
    sequence_data = "".join([line.strip().upper() for line in lines_in_file if not line.startswith('>')])

    # Calculate the sequence length
    sequence_length = len(sequence_data)
    
    # Define stop codons
    stop_codons = ['TAA', 'TAG', 'TGA']
    
    # Initialize list to store longest region for each reading frame
    longest_regions_per_frame = []
    
    # Loop through both the forward and reverse complement directions
    for direction in ['forward', 'reverse']:
        # Choose the sequence based on the direction
        sequence_to_use = sequence_data if direction == 'forward' else reverse_complement(sequence_data)
        
        # Loop through each of the three reading frames
        for reading_frame in range(3):
            # Initialize list to store all regions for this frame
            regions = []
            
            # Initialize the start position for the first region
            region_start = reading_frame
            
            # Loop through the sequence in steps of 3 bases
            for i in range(reading_frame, len(sequence_to_use), 3):
                # If near the end of the sequence, end the region
                if i + 3 > len(sequence_to_use):
                    regions.append((direction, reading_frame, region_start, i, i - region_start))
                    break
                
                # Extract the current codon
                codon = sequence_to_use[i:i + 3]
                
                # If a stop codon is found, end the region
                if codon in stop_codons:
                    regions.append((direction, reading_frame, region_start, i, i - region_start))
                    # Update the start position for the next region
                    region_start = i + 3

            # Find the longest region for this frame and add to list
            if regions:
                longest_regions_per_frame.append(max(regions, key=lambda x: x[4]))
            else:
                # If no regions, count the whole sequence as one region
                longest_regions_per_frame.append((direction, reading_frame, reading_frame, sequence_length, sequence_length))

    # Find the overall longest region across all frames and directions
    direction, frame, start, end, length = max(longest_regions_per_frame, key=lambda x: x[4])
    
    return sequence_id, direction, frame, start, end, length, sequence_length

# Main script logic
if __name__ == "__main__":
    # Get file paths from command line arguments
    fasta_file_path = sys.argv[1]
    output_file_path = sys.argv[2]

    # Run the function and store the results
    sequence_id, direction, frame, start, end, length, sequence_length = longest_non_stop_region(fasta_file_path)
    
    # Write the results to an output file
    with open(output_file_path, 'w') as output_file:
        output_file.write(f"{sequence_id},{direction},{frame + 1},{start + 1},{end},{length},{sequence_length - frame}\n")
