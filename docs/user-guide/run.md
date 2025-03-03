
# Overview: Run the Pipeline
To execute with Docker:
```bash
nextflow run main.nf -profile docker
```
To execute with Singularity:
```bash
nextflow run main.nf -profile singularity
```
To execute with the provided wrapper:
```bash
bash run_workflow.sh \
  -e <entry> \ #REQUIRED: arBASESPACE,arANALYSIS,arFORMAT,arREPORT,outbreakANALYSIS,outbreakREPORT"
  -i <projectID> \ #REQUIRED: test
  -r <resumeRun> \ #OPTIONAL: Y,N (default Y)
  -l <labResults> \ #OPTIONAL: path to the labResults file
  -m <metadata_NCBI> \ #OPTIONAL: path to the NCBI input metadata file
  -o <output_NCBI> \ #OPTIONAL: path to the NCBI output metadata file
  -n <nextflowParams> \ #OPTIONAL: nextflow commands (default -profile docker,test -entry NFCORE_ODHLAR --max_memory 7.GB --max_cpus 4)
```

# Worfklow

## arBASESPACE
### Description
The `arBASESPACE` workflow dwnloads files directly from Illumina Basespace.
### Input
| Type | Flag | Description | ExampleFile |
| -----| -----| ------------| -------------|
| Required | input | Samplesheet of input information | `assets/samplesheet.csv` |
| Required | projectID | Name of the project | `test` |
### Output
| File | WorkflowDestination |
| ---- | ------------------- | 
| `basespace/*fastq.gz` | arANALYSIS |

## arANALYSIS
### Description
The `arANALYSIS` workflow downloads file Illumina Basespace, if needed; performs **quality control, genome assembly, and taxonomic classification**; detects **antimicrobial resistance genes, plasmids, and virulence factors**.
### Input
| Type | Flag | Description | ExampleFile |
| -----| -----| ------------| -------------|
| Required | input | Samplesheet of input information | `assets/samplesheet.csv` |
| Required | projectID | Name of the project | `test` |
| Optional | runBASESPACE | Whether to run `basespace` to gather samples | `TRUE` or `FALSE` |
### Ouput
| File | WorkflowDestination |
| ---- | ------------------- | 
| `create_phoenix_summary_line/*summaryline.tsv` | arFORMAT |
| `get_trimd_stats/*_trimmed_read_counts.txt` | arFORMAT |
| `generate_pipeline_stats/*.synopsis` | arFORMAT |
| `basespace/*fastq.gz` | arFORMAT |
| `amrfinderplus_run/*all_genes.tsv` | arReport |
| `prokka/*gff` | outbreakANALYSIS |

## arFORMAT
### Description
The `arFORMAT` workflow performs **quality control**;  performs **generation of unique WGS ID's**; prepares **NCBI submission**.
### Input
| Type | Flag | Description | ExampleFile |
| -----| -----| ------------| -------------|
| Required | labResults | Quality control file of lab expected results | `assets/labResults_example.csv` |
| Required | analysis_outdir | Output directory from the arANALYSIS pipeline | `/path/to/arANALYSIS/directory` |
| Required | metadata_NCBI | Metadata file required for NCBI upload | `assets/metaData_ncbi_example.csv` |
| Required | config_NCBI | Config file for NCBI upload | `conf/config_NCBI.yaml` |
| Required | id_db | Database of ID's, include custom WGS and NCBI ID's | `assets/databases/IDdbs/db_master.csv` |
### Ouput
| File | WorkflowDestination |
| ---- | ------------------- | 
| `ncbi_prep/id_db_results_preNCBI.csv` | arREPORT |
| `post_process/processed_pipeline_results.csv` | arREPORT |

## arREPORT
### Description
The `arREPORT` workflow performs **NCBI processing**;  create **AR Basic Report**.
### Input
| Type | Flag | Description | ExampleFile |
| -----| -----| ------------| -------------|
| Required | format_outdir | Output directory from the arFORMAT pipeline | `/path/to/arFORMAT/ directory` |
| Required | analysis_outdir | Output directory from the arANALYSIS pipeline | `/path/to/arANALYSIS/directory` |
| Required | output_NCBI | Config file for arReport | `conf/config_ar_report.yaml` |
| Required | config_arReport | Config file for arReport | `conf/config_ar_report.yaml` |
### Ouput
| File | WorkflowDestination |
| ---- | ------------------- | 
| `report_basic/test_basicReport.html` | NA |
| `report_basic_prep/test_final_report.csv` | NA |

## outbreakANALYSIS
### Description
The `outbreakANALYSIS` workflow performs additional analysis for outbreak detection.
### Input
| Type | Flag | Description | ExampleFile |
| -----| -----| ------------| -------------|
| Required | projectID | Name of the project | `test` |
| Required | input_gff | Input samplesheet of gff input | `assets/samplesheet_gff.csv` |
| Required | outbreak_species | Name of the species to be analyzed | `pseudomonas` |
| Required | snp_config | Config file for snpPipeline | `conf/snppipipeline.conf` |
| Required | config_arReport | Config file for outbreakANALYSIS pipeline | `conf/config_ar_report.yaml` |
| Required | outbreak_metadata | Metadata file of outbreak samples | `/assets/metaData_outbreak.csv` |
| Required | reference_outdir | Directory of source outbreak files | `assets/databases/outbreak/` |
| Required | analysis_outdir | Output directory from the arANALYSIS pipeline | `/path/to/arANALYSIS/| 
| Required | report_outdir | Output directory from the arREPORT pipeline | `/path/to/arREPORT/directory` |
### Outbreak
| File | WorkflowDestination |
| ---- | ------------------- | 
| `report_outbreak/test_outbreakReport.html` | NA |