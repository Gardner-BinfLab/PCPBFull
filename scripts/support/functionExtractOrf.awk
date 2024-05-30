#!/usr/bin/awk -f

BEGIN {
    max_length = 0;
    current_length = 0;
    reading_protein = 0;
    current_header = "";
    current_protein = "";
    max_header = "";
    max_protein = "";
}

{
    if ($1 ~ /^>/) {
        if (reading_protein == 1) {
            if (current_length > max_length) {
                max_length = current_length;
                max_header = current_header;
                max_protein = current_protein;
            }
            
            # Reset temp variables
            current_length = 0;
            current_header = "";
            current_protein = "";
        }
        
        reading_protein = 0;
        current_header = $0;
        
        # Extract the length from the header
        for (i = 1; i <= NF; i++) {
            if ($i ~ /length=/) {
                split($i, arr, "=");
                current_length = arr[2];
            }
        }
    } else {
        if (reading_protein == 0) {
            reading_protein = 1;
        }
        
        current_protein = current_protein $0;
    }
}

END {
    if (current_length > max_length) {
        max_length = current_length;
        max_header = current_header;
        max_protein = current_protein;
    }
    
    print max_header;
    print max_protein;
}
