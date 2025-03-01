# ODHL_samplesheet
sample,fastq_1,fastq_2
ODHL_sample1,ODHL_sample1.R1.fastq.gz,ODHL_sample1.R2.fastq.gz
ODHL_sample2,ODHL_sample2.R1.fastq.gz,ODHL_sample2.R2.fastq.gz
ODHL_sample3,ODHL_sample3.R1.fastq.gz,ODHL_sample3.R2.fastq.gz
ODHL_sample4,ODHL_sample4.R1.fastq.gz,ODHL_sample4.R2.fastq.gz

# Lab Results
## true results
ODHL_sample1 Acinetobacter
ODHL_sample2 Acinetobacter
ODHL_sample3 Pseudomonas
ODHL_sample4 Pseudomonas
## labResults
sample,results
ODHL_sample1,Acinetobacter
ODHL_sample2,Acinetobacter
ODHL_sample3,Acinetobacter
ODHL_sample4,Pseudomonas

# Quality Results
## Sample1
This ODHL_sample will fail sequencing QC thresholds
-- COVERAGE                      : FAILED   : 4.16x coverage based on trimmed reads (Min:30x)
This ODHL_sample will pass lab QC thresholds

## Sample2
This ODHL_sample will pass sequencing QC thresholds
This ODHL_sample will pass lab QC thresholds

## Sample3
This ODHL_sample will pass sequencing QC thresholds
This ODHL_sample will fail lab QC thresholds
-- The results should be Pseudomonas, but reported as Acinetobacter

## Sample4
This ODHL_sample will pass sequencing QC thresholds
This ODHL_sample will pass lab QC thresholds

# Full workflow
```
# run arANALYSIS
bash run_workflow.sh -e arANALYSIS -i test

# run arFORMAT
bash run_workflow.sh -e arFORMAT -i test

# run arREPORT
bash run_workflow.sh -e arREPORT -i test

# run outbreakANALYSIS
bash run_workflow.sh -e outbreakANALYSIS -i test
```