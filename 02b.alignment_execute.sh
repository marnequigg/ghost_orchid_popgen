#!/bin/bash

# Sample list based on paired R1 files
SAMPLE_LIST=$(ls /home/imh4101/ghost_orchid_project/01.trimmed_reads/*_R1_paired.fastq.gz | sed 's|.*/||; s/_R1_paired.fastq.gz//' | sort -u)

# Run 5 samples in parallel
echo "$SAMPLE_LIST" | parallel -j 2 ./02a.align_samples.sh
