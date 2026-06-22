# Step 1: Filter raw VCF for quality and missingness
vcftools --vcf final.vcf --remove-indels --maf 0.05 --max-missing 0.50 --minQ 30 --min-meanDP 5 --max-meanDP 40 --minDP 10 --maxDP 40 --recode --recode-INFO-all --out final_strict

# Step 2: Restrict to biallelic SNPs
bcftools view -m2 -M2 -v snps /home/imh4101/ghost_orchid_project/10.vcf/final_strict.recode.vcf -Oz -o final_strict_bi.vcf
bcftools stats final_strict_bi.vcf
#0 multiallelic sites

# Step 3: Convert filtered VCF to PLINK format
plink --vcf final_strict_bi.vcf \
  --double-id --allow-extra-chr \
  --set-missing-var-ids @:# \
  --make-bed --out strict_bed

# Step 4: LD pruning
plink --bfile strict_bed \
  --allow-extra-chr \
  --indep-pairwise 50 10 0.1 \
  --out ghost_strict
#162 variants removed

# Step 5: Extract unlinked SNPs and export pruned VCF
plink --bfile strict_bed \
  --extract ghost_strict.prune.in \
  --allow-extra-chr \
  --mind 0.5 \
  --recode vcf \
  --out final_ghost_strict_LDpruned

### THIS IS THE VCF FILE FOR GENETIC DIVERSITY ###

# Step 6: Convert pruned VCF to PLINK format for downstream use
plink --vcf final_ghost_strict_LDpruned.vcf \
  --double-id --allow-extra-chr \
  --set-missing-var-ids @:# \
  --make-bed --out /home/imh4101/ghost_orchid_project/11.admixture/final_ghost_strict_LDpruned

# Step 7: Prepare input for ADMIXTURE
plink --bfile final_ghost_strict_LDpruned \
  --recode12 --out final_ghost_strict_LDpruned \
  --allow-extra-chr --double-id

# Step 8: Download ADMIXTURE wrapper
wget https://raw.githubusercontent.com/dportik/admixture-wrapper/master/admixture-wrapper.py
conda install numpy
cp /home/imh4101/ghost_orchid_project/10.vcf/final_ghost_strict_LDpruned.vcf /home/imh4101/ghost_orchid_project/11.admixture

# Step 9: Run ADMIXTURE with cross-validation
screen -L python3 admixture-wrapper.py \
  -i /home/imh4101/ghost_orchid_project/11.admixture \
  --kmin 1 --kmax 15 --reps 10 -t 10 --cv 10

# Step 10: Extract CV errors
cd /home/imh4101/ghost_orchid_project/11.admixture/Outputs-final_ghost_strict_LDpruned
grep "CV" *out | awk '{print $3,$4}' | sed -e 's/(//;s/)//;s/://;s/K=//' > combined.cv.error
