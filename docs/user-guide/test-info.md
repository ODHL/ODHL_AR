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
ODHL_sample1,Providencia
ODHL_sample2,Acinetobacter
ODHL_sample3,Pseudomonas
ODHL_sample4,Pseudomonas

## Expected Results
### Sample1
This ODHL_sample will fail sequencing QC thresholds
-- COVERAGE                      : FAILED   : 4.16x coverage based on trimmed reads (Min:30x)
This ODHL_sample will pass lab QC thresholds

### Sample2
This ODHL_sample will pass sequencing QC thresholds
This ODHL_sample will pass lab QC thresholds

### Sample3
This ODHL_sample will fail sequencing QC thresholds
This ODHL_sample will fail lab QC thresholds
-- The results should be Acinetobacter, but reported as Pseudomonas

### Sample4
This ODHL_sample will pass sequencing QC thresholds
This ODHL_sample will pass lab QC thresholds

# Running pipeline
To execute with Docker:
```bash
nextflow run main.nf -entry arANALYSIS -profile docker,test
```
To execute with Singularity:
```bash
nextflow run main.nf -entry arANALYSIS -profile singularity,test
```
To execute with the provided wrapper:
```bash
bash run_workflow.sh -e arANALYSIS -i test
```

# Running full workflow
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

# Expected results
Expected results are provided for each of the workflows. 
- **arANALYSIS**:  
  - **`create_phoenix_summary_line/`**: Contains summary line reports for individual samples (`ODHL_sample1_summaryline.tsv`, `ODHL_sample2_summaryline.tsv`, etc.), summarizing key results per sample.  

- **arFORMAT**:  
  - **`post_process/`**: Stores processed pipeline results, including:
    - `processed_pipeline_results.csv` – Consolidated results from the pipeline.  
    - `quality_results.csv` – Quality assessment results of the analysis.  

- **arREPORT**:  
  - **`report_basic/`**: Contains the **basic analysis report** (`test_basicReport.html`), providing a summarized overview of the pipeline outputs.  

- **outbreakANALYSIS**:  
  - **`test_outbreakReport.html`**: The **final outbreak analysis report**, summarizing key findings from the outbreak investigation.  