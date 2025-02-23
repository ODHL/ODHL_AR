# ODHL_samplesheet
sample,fastq_1,fastq_2
ODHL_sample1,ODHL_sample1.R1.fastq.gz,ODHL_sample1.R2.fastq.gz
ODHL_sample2,ODHL_sample2.R1.fastq.gz,ODHL_sample2.R2.fastq.gz
ODHL_sample3,ODHL_sample3.R1.fastq.gz,ODHL_sample3.R2.fastq.gz
ODHL_sample4,ODHL_sample4.R1.fastq.gz,ODHL_sample4.R2.fastq.gz

# labResults
sample,results
ODHL_sample1,Providencia
ODHL_sample2,Acinetobacter
ODHL_sample3,Pseudomonas
ODHL_sample4,Pseudomonas

# Sample1
This ODHL_sample will fail sequencing QC thresholds
COVERAGE                      : FAILED   : 4.16x coverage based on trimmed reads (Min:30x)

# Sample2
This ODHL_sample will pass sequencing QC thresholds
This ODHL_sample will pass lab QC thresholds

# Sample3
This ODHL_sample will pass sequencing QC thresholds
This ODHL_sample will fail lab QC thresholds
-- The results should be Acinetobacter, but reported as Providencia

# Sample4
This ODHL_sample will pass sequencing QC thresholds
This ODHL_sample will pass lab QC thresholds