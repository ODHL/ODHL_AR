# samplesheet
sample,fastq_1,fastq_2
24AR004033-OH-VH00648-241004,24AR004033.R1.fastq.gz,24AR004033.R2.fastq.gz
24AR005293-OH-VH01632-241210,24AR005293.R1.fastq.gz,24AR005293.R2.fastq.gz
24AR005295-OH-VH01632-241210,24AR005295.R1.fastq.gz,24AR005295.R2.fastq.gz
24AR005296-OH-VH01632-241210,24AR005296.R1.fastq.gz,24AR005296.R2.fastq.gz

# labResults
sample,results
24AR004033-OH-VH00648-241004,Providencia
24AR005293-OH-VH01632-241210,Acinetobacter
24AR005295-OH-VH01632-241210,Klebsiella
24AR005296-OH-VH01632-241210,Pseudomonas


# Sample 24AR004033-OH-VH00648-241004
This sample will fail QC thesholds.
KRAKEN2_CLASSIFY_WEIGHTED     : FAILED   : Genus-Acinetobacter is under 70% (species-baumannii 66.25%), likely contaminated
ASSEMBLY_RATIO(SD)            : FAILED   : St. dev. too large - 1.8449x(7.4691-SD) against P.stuartii
COVERAGE                      : FAILED   : 4.16x coverage based on trimmed reads (Min:30x)

# Sample 24AR005293-OH-VH01632-241210
This sample will pass all QC thresholds.

# Sample 24AR005295-OH-VH01632-241210
This sample will fail QC thresholds.
The results should be Pseudomonas, but reported as Klebsiella

# Sample 24AR005296-OH-VH01632-241210
This sample will pass all QC thresholdss.