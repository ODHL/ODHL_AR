# ODHL_samplesheet
ODHL_sample,fastq_1,fastq_2
ODHL_sample1,ODHL_sample1.R1.fastq.gz,ODHL_sample1.R2.fastq.gz
ODHL_sample2,ODHL_sample2.R1.fastq.gz,ODHL_sample2.R2.fastq.gz
ODHL_sample3,ODHL_sample3.R1.fastq.gz,ODHL_sample3.R2.fastq.gz
ODHL_sample4,ODHL_sample4.R1.fastq.gz,ODHL_sample4.R2.fastq.gz

# labResults
ODHL_sample,results
ODHL_sample1,Providencia
ODHL_sample2,Acinetobacter
ODHL_sample3,Klebsiella
ODHL_sample4,Pseudomonas

# Sample1
This ODHL_sample will fail QC thesholds.
KRAKEN2_CLASSIFY_WEIGHTED     : FAILED   : Genus-Acinetobacter is under 70% (species-baumannii 66.25%), likely contaminated
ASSEMBLY_RATIO(SD)            : FAILED   : St. dev. too large - 1.8449x(7.4691-SD) against P.stuartii
COVERAGE                      : FAILED   : 4.16x coverage based on trimmed reads (Min:30x)

# Sample2
This ODHL_sample will pass all QC thresholds.

# Sample3
This ODHL_sample will fail QC thresholds.
The results should be Pseudomonas, but reported as Klebsiella

# Sample4
This ODHL_sample will pass all QC thresholdss.