#!/usr/bin/bash

# Setup coding potential project

# Sanity check for location and correct shell
echo " "
sleep 0.1
read -p "Are you running this in the base project folder? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting"
    echo " "
    exit 1
fi

# import config settings
source config/main.config.cfg

mkdir -p data/databases
mkdir -p data/genomes
mkdir -p "${compiledResultsFolder}"

sleep 1
