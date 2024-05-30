#!/usr/bin/env python3

import os
import argparse
from Bio import SeqIO
from Bio.Seq import Seq

def reverse_complement(seq):
    """Generate the reverse complement of a DNA sequence."""
    return str(Seq(seq).reverse_complement())

def modify_fasta(file_path, destination):
    """Modify FASTA files to include only reverse complements."""
    with open(file_path, 'r') as original_file:
        for record in SeqIO.parse(original_file, 'fasta'):
            original_id = record.id  # Store the original ID
            modified_seq = reverse_complement(record.seq)
            new_record = record[:]
            new_record.seq = Seq(modified_seq)
            new_record.id = f"{original_id}_revComp"  # Append '_revComp' to the original ID
            new_record.description = new_record.id  # Update the description
            new_file_path = os.path.join(destination, f"{new_record.id}.fa")
            SeqIO.write(new_record, new_file_path, 'fasta')

def main():
    # Set up the argument parser
    parser = argparse.ArgumentParser(description='Process some fasta files.')
    parser.add_argument('--destination', required=True, help='The destination directory for modified files')
    parser.add_argument('--fasta_files_path', required=True, help='Path to the file containing list of FASTA files')
    
    # Parse arguments from command line
    args = parser.parse_args()

    # Create destination directory if it doesn't exist
    if not os.path.exists(args.destination):
        os.makedirs(args.destination)
    
    # Process each file listed in the text file
    with open(args.fasta_files_path, 'r') as file_list:
        for line in file_list:
            fasta_path = line.strip()
            if os.path.exists(fasta_path):
                modify_fasta(fasta_path, args.destination)
            else:
                print(f"Warning: {fasta_path} does not exist")

if __name__ == "__main__":
    main()
