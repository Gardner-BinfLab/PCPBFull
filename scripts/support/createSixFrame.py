#!/usr/bin/env python3

import os
from Bio import SeqIO
from Bio.Seq import Seq

def reverse_complement(seq):
    return str(Seq(seq).reverse_complement())

def modify_fasta(file_path, destination, modifications):
    with open(file_path, 'r') as original_file:
        for record in SeqIO.parse(original_file, 'fasta'):
            original_id = record.id  # Store the original ID to avoid accumulation of modifications
            original_seq = str(record.seq)[69:]  # Remove the first 69 nucleotides
            for mod_name, mod_function in modifications.items():
                modified_seq = mod_function(original_seq)
                new_record = record[:]
                new_record.seq = Seq(modified_seq)
                new_record.id = f"{original_id}_{mod_name}"  # Use the original ID with modification
                new_record.description = new_record.id  # Update the description to match the new ID
                new_file_path = os.path.join(destination, f"{original_id}_{mod_name}.fa")
                SeqIO.write(new_record, new_file_path, 'fasta')

def main():
    destination = 'data/resultingSeqs/sixFrame'
    forSixFrame_path = 'results/misc/top15.txt'
    modifications = {
        'original': lambda x: x,
        'minus1': lambda x: x[1:],
        'minus2': lambda x: x[2:],
        'revComp': reverse_complement,
        'revComp_minus1': lambda x: reverse_complement(x)[1:],
        'revComp_minus2': lambda x: reverse_complement(x)[2:]
    }
    
    if not os.path.exists(destination):
        os.makedirs(destination)
    
    with open(forSixFrame_path, 'r') as file_list:
        for line in file_list:
            fasta_path = line.strip()
            if os.path.exists(fasta_path):
                modify_fasta(fasta_path, destination, modifications)
            else:
                print(f"Warning: {fasta_path} does not exist")

if __name__ == "__main__":
    main()
