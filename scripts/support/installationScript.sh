#!/usr/bin/bash

# Do not run this script directly. It is called from the install script


datafile="paperData.zip"

# Check if zip file exists or has been extracted.
if [[ -e ${datafile} ]]; then
    echo "Extracting . . ."
    unzip ${datafile} && rm ${datafile}
    echo "Extracted"
else 
    echo "Data previously extracted (or maybe missing?!)"
    read -p "Are you sure you want to continue? " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting"
        echo " "
        exit 1
    fi
fi

