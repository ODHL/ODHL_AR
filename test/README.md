# samplesheet
sample,fastq_1,fastq_2
sample1,sample1.R1.fastq.gz,sample1.R2.fastq.gz
sample2,sample2.R1.fastq.gz,sample2.R2.fastq.gz
sample3,sample3.R1.fastq.gz,sample3.R2.fastq.gz
sample4,sample4.R1.fastq.gz,sample4.R2.fastq.gz

# labResults
sample,results
sample1,Providencia
sample2,Acinetobacter
sample3,Klebsiella
sample4,Pseudomonas

# Sample1
This sample will fail QC thesholds.
KRAKEN2_CLASSIFY_WEIGHTED     : FAILED   : Genus-Acinetobacter is under 70% (species-baumannii 66.25%), likely contaminated
ASSEMBLY_RATIO(SD)            : FAILED   : St. dev. too large - 1.8449x(7.4691-SD) against P.stuartii
COVERAGE                      : FAILED   : 4.16x coverage based on trimmed reads (Min:30x)

# Sample2
This sample will pass all QC thresholds.

# Sample3
This sample will fail QC thresholds.
The results should be Pseudomonas, but reported as Klebsiella

# Sample4
This sample will pass all QC thresholdss.