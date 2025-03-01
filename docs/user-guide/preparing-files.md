
# Input Format
## Samplesheet (Required)
Each project requires an `input` CSV formatted file.

| sample | fastq_1 | fastq_2 |
|-----------|--------|--------|
| Sample1   | Sample1_R1.fastq.gz | Sample1_R2.fastq.gz |
| Sample2   | Sample2_R1.fastq.gz | Sample2_R2.fastq.gz |

```
sample,fastq_1,fastq_2
sample1,/path/to/fastq/files/sample1.R1.fastq.gz,/path/to/fastq/files/sample1.R2.fastq.gz
sample2,/path/to/fastq/files/sample2.R1.fastq.gz,/path/to/fastq/files/sample2.R2.fastq.gz
```

## labResults (Optional)
Each project can check laboratory QC with an `labResults` CSV formatted file.

| sample | results |
|-----------|--------|
| Sample1   | expectedSpecies |
| Sample2   | expectedSpecie2 |

```
sample,results
sample1,expectedSpecies
sample2,expectedSpecies2
```

## metadata_NCBI (Optional)
Each project can upload to NCBI with an `metadata_NCBI` tab formatted file.

| Specimen ID | Last Name | First Name | Birth Date | Sex | City | State | ZIP Code | County | Specimen Host | Isolation Source | Source Other | Healthcare Origin | Healthcare State | Healthcare ZIP | Submitter Name | Submitter State | Submitter ZIP | Organism Genus | Organism Species | Collect Date | Date Received |
|------------|-----------|------------|------------|-----|------|-------|----------|--------|--------------|-----------------|--------------|----------------|----------------|--------------|---------------|----------------|--------------|--------------|----------------|---------------|---------------|
| sample1 | person1 | person1 | 9/19/1948 | 1 | ATHENS | OH | 45701 | ATHENS | 1 | SWAB_WOUND |  | LAURELS OF ATHENS, THE | OH | 45701 | HEALTH_ASSOCIATES | OH | 44132 | ACINETOBACTER | BAUMANNII | 8/6/2024 | 8/14/2024 |
| sample2 | person2 | person2 | 4/26/1953 | 2 | LEBANON | IL | 62254 | ST. CLAIR | 1 | SWAB_WOUND |  |  | IL |  | HEALTH_ASSOCIATES | OH | 44132 | ACINETOBACTER | BAUMANNII | 7/31/2024 | 8/14/2024 |
| sample3 | person3 | person3 | 3/17/1957 | 1 | BELLEVUE | OH | 44811 | SANDUSKY | 1 | URINE_CATHETER (STRAIGHT) |  | CLEVELAND CLINIC | OH | 44195 | HEALTH_ASSOCIATES | OH | 44106 | PSEUDOMONAS | AERUGINOSA | 8/11/2024 | 8/16/2024 |

```
specimen_id	name_last	name_first	birth_date	sex	pt_city	pt_state	pt_zip	pt_county	specimen_host	isolation_source	source_other	healthcare_origin	healthcare_state	healthcare_zip	submitter_name	submitter_state	submitter_zip	organism_genus	organism_species	collect_date	date_received
sample1	person1	person1	9/19/1948	1	ATHENS	OH	45701	ATHENS	1	SWAB_WOUND		LAURELS OF ATHENS, THE	OH	45701	HEALTH_ASSOCIATES	OH	44132	ACINETOBACTER	BAUMANNII	8/6/2024	8/14/2024
sample2	person2	person2	4/26/1953	2	LEBANON	IL	62254	ST. CLAIR	1	SWAB_WOUND			IL		HEALTH_ASSOCIATES	OH	44132	ACINETOBACTER	BAUMANNII	7/31/2024	8/14/2024
sample3	person3	person3	3/17/1957	1	BELLEVUE	OH	44811	SANDUSKY	1	URINE_CATHETER (STRAIGHT)		CLEVELAND CLINIC	OH	44195	HEALTH_ASSOCIATES	OH	44106	PSEUDOMONAS	AERUGINOSA	8/11/2024	8/16/2024
```

# Reference Databases
## Kraken2 Database
The database file can be taken from [`Ben Langmead's repository`](https://benlangmead.github.io/aws-indexes/k2) which links directly to the database file. It is recommended to use the latest version of the [`8GB database`](https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20240904.tar.gz), and reformat it using the `bin/reformat_kraken.sh` script.

```bash
#!/bin/bash
# bash reformat_kraken2.sh 202401 k2_standard_08gb_20240112.tar.gz

tag=$1
kraken_db=$2
kraken_output="k2_standard_08gb_reformat_${tag}.tar.gz"

if [[ ${kraken_db} == *.tar.gz ]]; then
        echo "Preparing K2 directory: from ${kraken_db} to  ${kraken_output}"

        # Use standard gzip for decompression
        tar -xzf "${kraken_db}" || {
                echo "Error: Failed to extract ${kraken_db}" >&2
                exit 1
        }

        # create the final dir
        mkdir -p "${kraken_output}"
        mv *.kmer_distrib *.k2d seqid2taxid.map inspect.txt ktaxonomy.tsv "${kraken_output}" 2>/dev/null || {
                echo "Warning: Some expected files were not found."
        }
elif
        echo "Output already exists: ${kraken_output}"
fi
```
## All Other Databases
All other databases come pre-packaged with the pipeline
    
    - REFSEQ_20240124_Bacteria_complete.msh.gz
    - mlst_db_20240124.tar.gz
    - phiX.fasta
    - nodes_20240129.dmp.gz
    - names_20240129.dmp.gz
    - HyperVirulence_20220414.fasta
    - ResGANNCBI_20240131_srst2.fasta
    - PF-Replicons_20240124.fasta
    - amrfinderdb_v3.12_20240131.1.tar.gz
    - NCBI_Assembly_stats_20240124.txt
