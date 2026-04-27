#!/bin/bash

set -uo pipefail
SAMPLE="$1"

# Paths
FASTQ_DIR="/home/imh4101/ghost_orchid_project/01.trimmed_reads"
REFERENCE="/home/imh4101/ghost_orchid_project/00.references/Orchidaceae963.fa"
ALIGNMENT_DIR="/home/imh4101/ghost_orchid_project"
BAM_DIR="$ALIGNMENT_DIR/02.bams"
SORTED_DIR="$ALIGNMENT_DIR/03.sorted_bams"
FLAGSTAT_DIR="$ALIGNMENT_DIR/04.flagstats"
LOGFILE="$ALIGNMENT_DIR/align_status.log"

mkdir -p "$BAM_DIR" "$SORTED_DIR" "$FLAGSTAT_DIR"

R1="$FASTQ_DIR/${SAMPLE}_R1_paired.fastq.gz"
R2="$FASTQ_DIR/${SAMPLE}_R2_paired.fastq.gz"
SAM="$ALIGNMENT_DIR/${SAMPLE}.sam"
BAM="$BAM_DIR/${SAMPLE}.bam"
SORTED="$SORTED_DIR/${SAMPLE}_sorted.bam"
NSORT="$ALIGNMENT_DIR/${SAMPLE}_nsort.sam"
FLAGSTAT="$FLAGSTAT_DIR/${SAMPLE}_flagstat.txt"

# Logging functions
log()   { echo -e "[\033[1;36m$SAMPLE\033[0m] $1"; }
status(){ echo -e "${SAMPLE}\t$1\t$2" >> "$LOGFILE"; }

# Input check
[[ ! -f "$R1" || ! -f "$R2" ]] && status "FAILED" "Missing FASTQs" && exit 1

log "Aligning with BWA..."
if ! bwa mem -M -t 10 "$REFERENCE" "$R1" "$R2" > "$SAM"; then
    status "FAILED" "bwa mem error" && exit 2
fi

log "Converting SAM to BAM..."
if ! samtools view -b "$SAM" -o "$BAM"; then
    status "FAILED" "SAM to BAM failed" && exit 3
fi

log "Sorting BAM by coordinate..."
if ! samtools sort -o "$SORTED" "$BAM"; then
    status "FAILED" "BAM sort failed" && exit 4
fi

log "Generating flagstat..."
if ! samtools flagstat "$SORTED" > "$FLAGSTAT"; then
    status "FAILED" "flagstat failed" && exit 5
fi

log "Sorting SAM by read name..."
if ! samtools sort -n "$SAM" -o "$NSORT"; then
    status "FAILED" "name sort failed" && exit 6
fi

log "✅ Sample completed successfully."
status "SUCCESS" "All steps completed"
