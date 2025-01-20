# Getting Started

## Introduction
**ODHL_AR** is a bioinformatics best-practice pipeline for detecting antimicrobial resistance (AMR) genes and assessing bacterial genomic characteristics from whole-genome sequencing (WGS) data.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool that efficiently runs tasks across multiple compute infrastructures in a portable and scalable manner. It uses Docker/Singularity containers, making installation trivial and ensuring reproducible results.

---

## Pipeline Summary

1. **Read QC**: [`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) – Provides quality metrics for raw sequencing reads.
2. **Trimming reads**: [`Fastp`](https://github.com/OpenGene/fastp) – Trims low-quality reads and adapter sequences.
3. **Taxonomic Classification**: [`Kraken2`](https://ccb.jhu.edu/software/kraken2/) – Identifies bacterial species present in the sequencing data.
4. **Genome Assembly**: [`SPAdes`](https://cab.spbu.ru/software/spades/) – Performs de novo genome assembly.
5. **Quality Assessment of Assembly**: [`QUAST`](http://quast.sourceforge.net/) – Evaluates assembly quality.
6. **Plasmid Identification**: [`PlasmidFinder`](https://cge.food.dtu.dk/services/PlasmidFinder/) – Detects plasmids in the assembled genome.
7. **MLST Typing**: [`MLST`](https://github.com/tseemann/mlst) – Determines **Multilocus Sequence Typing (MLST)** for bacterial isolates.
8. **AMR Gene Detection**: [`AMRFinderPlus`](https://www.ncbi.nlm.nih.gov/pathogens/antimicrobial-resistance/AMRFinder/) – Identifies antimicrobial resistance genes.
9. **Virulence Gene Detection**: [`Gamma`](https://github.com/) – Predicts bacterial virulence factors.
10. **Genome Annotation**: [`Prokka`](https://github.com/tseemann/prokka) – Annotates genomic features.
11. **Whole-Genome Comparisons**:
    - [`Mash`](https://github.com/marbl/Mash) – Estimates genome distances for clustering.
    - [`FastANI`](https://github.com/ParBLiSS/FastANI) – Calculates Average Nucleotide Identity (ANI) for species identification.
12. **Final Report**: [`MultiQC`](http://multiqc.info/) – Summarizes results across all samples in a single interactive report.

---

## Entry Points

Currently, there are several entry points for the AR pipeline:

1. `arBASESPACE`: Downloads files directly from Illumina Basespace.
2. `arANALYSIS`: Performs **quality control, genome assembly, and taxonomic classification**, detects **antimicrobial resistance genes, plasmids, and virulence factors**, and performs **generation of unique WGS ID's, and preparation of files for NCBI submission**.
4. `DBProcessing`: Performs **quality control, compiles NCBI ID's into a compiled user file**.
5. `outbreakANALYSIS`: Performs additional analysis for outbreak detection.
6. `outbreakREPORTING`: Generates reports depending on the type of outbreak analysis required.

Several workflows have been compiled into additional entry points for the AR pipeline:
1. `NFCORE_ODHLAR`: Executes **arBASESPACE** and **AR_ANALYSIS** for an **end-to-end workflow**.
2. `NFCORE_OUTBREAK`: Executes **outbreakANALYSIS** and **outbreakREPORTING** for an second **end-to-end workflow**.

---

## Processes

### **Quality Control & Preprocessing**
- **FastQC**: Provides sequencing quality metrics.
- **Fastp**: Trims low-quality reads and removes adapters.
- **Kraken2**: Classifies bacterial species from sequencing data.

### **Genome Assembly & Assessment**
- **SPAdes**: Performs de novo genome assembly.
- **QUAST**: Evaluates assembly quality.
- **PlasmidFinder**: Identifies plasmid sequences in assembled genomes.

### **Genotyping & Comparative Genomics**
- **MLST**: Identifies bacterial strain types.
- **Mash**: Estimates genetic distances between isolates.
- **FastANI**: Computes **Average Nucleotide Identity (ANI)** for species classification.

### **Antimicrobial Resistance & Virulence Detection**
- **AMRFinderPlus**: Detects AMR genes in bacterial genomes.
- **Gamma**: Predicts virulence factors from genomic data.

### **Genome Annotation**
- **Prokka**: Annotates bacterial genomes.

### **Final Reports**
- **MultiQC**: Compiles a summary of all quality control and analysis results.

---

## [Dependencies](#dependencies)

### **Software & Tools**
Ensure that the following software is installed before running the pipeline:

- [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=21.04.0`)
- [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/)
- [`Conda`](https://conda.io/miniconda.html) (Optional)

### **Core Software Versions**
The pipeline requires the following tools:

```plaintext
- Python 3.9
- Samtools 1.21
- FastQC 0.12.1
- Fastp 0.23.4
- Kraken2 2.1.2
- SPAdes 3.15.5
- QUAST 5.0.2
- PlasmidFinder 2.1
- MLST 2.23.0
- Mash 2.3
- FastANI 1.33
- AMRFinderPlus 3.10
- Gamma 2.2
- Prokka 1.14.5
- MultiQC 1.21
```

### Reference Databases
#### Kraken2 DB
The database file can be taken from [`Ben Langmead's repository`](https://benlangmead.github.io/aws-indexes/k2) which links directly to the database file. It is recommended to use the latest version of the [`8GB database`](https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20240904.tar.gz), and reformat it using the `bin/reformat_kraken.sh` script.

## **Pipeline Execution**
The **ODHL_rAcecaR pipeline** is implemented using **Nextflow**, which allows for execution on **local machines, HPC clusters, or cloud environments**.

### **1. Install Nextflow**
```bash
curl -s https://get.nextflow.io | bash
mv nextflow ~/bin/
```

### **2. Clone the Repository**
```bash
git clone https://github.com/ODHL/ODHL_rAcecaR.git
cd ODHL_rAcecaR
```

### **3. Configure the Pipeline**
Modify the **Nextflow configuration file (`nextflow.config`)** to specify reference databases and execution profiles.

Example modification:
```groovy
params {
    kraken2_db = "/home/ubuntu/refs/k2/k2_standard_08gb_202412.tar.gz"
    amrfinder_db = "/home/ubuntu/refs/amrfinderplus/latest"
    plasmidfinder_db = "/home/ubuntu/refs/plasmidfinder/latest"
}
```
---

## **Reproducibility**
To ensure **consistent results**, specify the pipeline version when running:

```bash
nextflow run ODHL/ODHL_AR -r 1.0.0
```

You can check for the latest version on the **[ODHL/ODHL_AR GitHub Releases page](https://github.com/ODHL/ODHL_AR/releases/)**.

---