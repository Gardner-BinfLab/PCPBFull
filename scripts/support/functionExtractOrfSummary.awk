#!/usr/bin/awk -f

BEGIN {
    # Print the header for the output file
    print "Name,Length";
}

{
    # Only process header lines that start with ">"
    if ($0 ~ /^>/) {
        # Extract the source and length using AWK's match function
        if (match($0, /source=[^ ]+/)) {
            source_substr = substr($0, RSTART, RLENGTH);
            split(source_substr, source_arr, "=");
            source = source_arr[2];
        }
        
        if (match($0, /length=[0-9]+/)) {
            len_substr = substr($0, RSTART, RLENGTH);
            split(len_substr, len_arr, "=");
            orf_length = len_arr[2];
        }
        
        # Print the source and length, separated by a tab
        printf "%s,%s\n", source, orf_length;
    }
}
