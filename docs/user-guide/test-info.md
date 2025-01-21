# Test data
## Overview
Four test samples are included with the pipeline. Two samples will fail tresholds (one failing pipeline thresholds, one failing the labroatory threshold) and two which will pass.

## Samplesheet
sample,fastq_1,fastq_2
sample1,sample1.R1.fastq.gz,sample1.R2.fastq.gz
sample2,sample2.R1.fastq.gz,sample2.R2.fastq.gz
sample3,sample3.R1.fastq.gz,sample3.R2.fastq.gz
sample4,sample4.R1.fastq.gz,sample4.R2.fastq.gz

## Lab Results
sample,results
sample,results
sample1,Providencia
sample2,Acinetobacter
sample3,Klebsiella
sample4,Pseudomonas

## Expected Results
### Sample1
This sample will fail QC thesholds.
KRAKEN2_CLASSIFY_WEIGHTED     : FAILED   : Genus-Acinetobacter is under 70% (species-baumannii 66.25%), likely contaminated
ASSEMBLY_RATIO(SD)            : FAILED   : St. dev. too large - 1.8449x(7.4691-SD) against P.stuartii
COVERAGE                      : FAILED   : 4.16x coverage based on trimmed reads (Min:30x)

### Sample2
This sample will pass all QC thresholds.

### Sample3
This sample will fail QC thresholds.
The results should be Pseudomonas, but reported as Klebsiella

### Sample4
This sample will pass all QC thresholdss.

# Running pipeline
To execute with Docker:
```bash
nextflow run main.nf -entry arBASESPACE -profile docker,test
```
To execute with Singularity:
```bash
nextflow run main.nf -entry arBASESPACE -profile singularity,test
```
To execute with the provided wrapper:
```bash
bash run_workflow.sh \
  -e arBASESPACE \
  -i test
```