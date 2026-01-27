#make a new conda
conda create -n ghostie
conda activate ghostie
conda config --add channels bioconda
conda config --add channels conda-forge
conda install trimmomatic #version 0.40

#change the file names
for filename in *fastq.gz;  do mv "$filename" "$(echo "$filename" | sed 's/_001.fastq.gz/.fastq.gz/')"; done
