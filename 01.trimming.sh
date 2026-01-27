cd /data/labs/Fant/Quigg/ghost_orchid_project/00.raw_data

nano trimming.sh

#!/bin/bash
# For loop to process all R1 samples
for R1 in *_R1.fastq.gz; do
    R2=${R1//_R1.fastq.gz/_R2.fastq.gz}
    R1p=${R1//.fastq.gz/_paired.fastq.gz}
    R1u=${R1//.fastq.gz/_unpaired.fastq.gz}
    R2p=${R2//.fastq.gz/_paired.fastq.gz}
    R2u=${R2//.fastq.gz/_unpaired.fastq.gz}

    # Run Trimmomatic
trimmomatic PE -phred33 \
-threads 20 "$R1" "$R2" "$R1p" "$R1u" "$R2p" "$R2u" \
ILLUMINACLIP:/home/imh4101/miniconda3/envs/ghostie/share/trimmomatic-0.40-0/adapters/TruSeq3-PE.fa:2:30:10:2:true \
LEADING:10 TRAILING:10 SLIDINGWINDOW:4:20 MINLEN:40

done
#exit

chmod +x trimming.sh
screen -L ./trimming.sh
