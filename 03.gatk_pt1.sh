#!/bin/bash

set -x

set -euo pipefail

# Reference genome
REF_GENOME="/home/imh4101/ghost_orchid_project/00.references/Orchidaceae963.fa"

# Output base directory
BASE_OUT="/home/imh4101/ghost_orchid_project"
SORTED_DIR="$BASE_OUT/03.sorted_bams"
DEDUP_DIR="$BASE_OUT/04.deduplicated_bams"
RG_DIR="$BASE_OUT/05.rg_bams"
GVCF_DIR="$BASE_OUT/06.gvcfs"
METRICS_DIR="$BASE_OUT/metrics"

# Create subdirectories
mkdir -p "$BASE_OUT" "$SORTED_DIR" "$DEDUP_DIR" "$RG_DIR" "$GVCF_DIR" "$METRICS_DIR"

process_sample() {
  BAM="$1"
  filename=$(basename "$BAM")
  SAMPLE_ID=$(echo "$filename" | cut -d'_' -f1)
  BATCH="SINGLE"

  echo -e "\n🔬 Processing $BAM for sample $SAMPLE_ID (batch $BATCH)"

  # Step 0: Sort BAM by coordinate
  SORTED_BAM="$SORTED_DIR/${SAMPLE_ID}_${BATCH}_sorted.bam"
  samtools sort -o "$SORTED_BAM" "$BAM"

  echo "Sorting complete for $SAMPLE_ID."

  # Step 1: MarkDuplicates
  MARKED_BAM="$DEDUP_DIR/${SAMPLE_ID}_${BATCH}_marked.bam"
  METRICS_FILE="$METRICS_DIR/${SAMPLE_ID}_${BATCH}_dedup.metrics.txt"
  gatk MarkDuplicates \
    I="$SORTED_BAM" \
    O="$MARKED_BAM" \
    M="$METRICS_FILE" \
    REMOVE_DUPLICATES=false \
    VALIDATION_STRINGENCY=SILENT

    echo "Duplicate marking complete for $SAMPLE_ID."

  # Step 2: AddOrReplaceReadGroups
  RGID="${SAMPLE_ID}_${BATCH}"
  RGLB="lib_${BATCH}"
  RGPL="illumina"
  RGPU="${BATCH}_unit"
  RGSM="$SAMPLE_ID"

  RG_BAM="$RG_DIR/${SAMPLE_ID}_${BATCH}_rg.bam"
  picard AddOrReplaceReadGroups \
    I="$MARKED_BAM" \
    O="$RG_BAM" \
    RGID="$RGID" \
    RGLB="$RGLB" \
    RGPL="$RGPL" \
    RGPU="$RGPU" \
    RGSM="$RGSM" \
    VALIDATION_STRINGENCY=SILENT

    echo "Read group addition complete for $SAMPLE_ID."

  samtools index "$RG_BAM"

  echo "Indexing complete for $SAMPLE_ID."

  # Step 3: HaplotypeCaller (GVCF mode)
  GVCF="$GVCF_DIR/${SAMPLE_ID}_${BATCH}.g.vcf.gz"
  gatk HaplotypeCaller \
    -R "$REF_GENOME" \
    -I "$RG_BAM" \
    -O "$GVCF" \
    -ERC GVCF \
    --native-pair-hmm-threads 4

    echo "Variant calling complete for $SAMPLE_ID."

  echo "✅ Finished $SAMPLE_ID"
}

export -f process_sample
export REF_GENOME BASE_OUT SORTED_DIR DEDUP_DIR RG_DIR GVCF_DIR METRICS_DIR

# Run the function on every BAM file
for BAM in /home/imh4101/ghost_orchid_project/03.sorted_bams/*_sorted.bam; do
    process_sample "$BAM"
done
