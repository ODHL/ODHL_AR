# Getting Started

## Introduction
**ODHL_AR** is a bioinformatics best-practice pipeline for detecting antimicrobial resistance (AMR) genes and assessing bacterial genomic characteristics from whole-genome sequencing (WGS) data.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool that efficiently runs tasks across multiple compute infrastructures in a portable and scalable manner. It uses Docker/Singularity containers, making installation trivial and ensuring reproducible results.

---

## Pipeline Summary

The pipeline includes several process, including the following:

### **Quality Control & Preprocessing**  
- **Read QC**: [`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) – Provides quality metrics for raw sequencing reads.  
- **Trimming Reads**: [`Fastp`](https://github.com/OpenGene/fastp) – Trims low-quality reads and adapter sequences.  
- **Taxonomic Classification**: [`Kraken2`](https://ccb.jhu.edu/software/kraken2/) – Identifies bacterial species present in the sequencing data.  

### **Genome Assembly & Assessment**  
- **Genome Assembly**: [`SPAdes`](https://cab.spbu.ru/software/spades/) – Performs de novo genome assembly.  
- **Quality Assessment of Assembly**: [`QUAST`](http://quast.sourceforge.net/) – Evaluates assembly quality.  
- **Plasmid Identification**: [`PlasmidFinder`](https://cge.food.dtu.dk/services/PlasmidFinder/) – Detects plasmids in the assembled genome.  

### **Genotyping & Comparative Genomics**  
- **MLST Typing**: [`MLST`](https://github.com/tseemann/mlst) – Determines **Multilocus Sequence Typing (MLST)** for bacterial isolates.  
- **Whole-Genome Comparisons**:  
  - [`Mash`](https://github.com/marbl/Mash) – Estimates genome distances for clustering.  
  - [`FastANI`](https://github.com/ParBLiSS/FastANI) – Calculates **Average Nucleotide Identity (ANI)** for species identification.  

### **Antimicrobial Resistance & Virulence Detection**  
- **AMR Gene Detection**: [`AMRFinderPlus`](https://www.ncbi.nlm.nih.gov/pathogens/antimicrobial-resistance/AMRFinder/) – Identifies antimicrobial resistance genes.  
- **Virulence Gene Detection**: [`Gamma`](https://github.com/) – Predicts bacterial virulence factors.  

### **Genome Annotation**  
- **Prokka**: [`Prokka`](https://github.com/tseemann/prokka) – Annotates bacterial genomes.  

### **Final Reports**  
- **MultiQC**: [`MultiQC`](http://multiqc.info/) – Summarizes results across all samples in a single interactive report.  

## Entry Points

Currently, there are several entry points for the AR pipeline:

1. `arBASESPACE`: Downloads files directly from Illumina Basespace.
2. `arANALYSIS`: Downloads file Illumina Basespace, if needed; performs **quality control, genome assembly, and taxonomic classification**; detects **antimicrobial resistance genes, plasmids, and virulence factors**.
3. `arFORMAT`: Performs **quality control**;  performs **generation of unique WGS ID's**; preparaes **NCBI submission**.
4. `arREPORT`: Performs **NCBI processing**;  create **AR Basic Report**.

In addition there are several entry points for AR outbreak analysis.

1. `outbreakANALYSIS`: Performs additional analysis for outbreak detection.
2. `outbreakREPORTING`: Generates reports depending on the type of outbreak analysis required.
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

### *** 4. (Optional) Install Basespace**
The pipeline allows for automatic download from basespace. If you choose to use this feature, you'll need to add basespace to your $PATH.
```bash
# Install basespace
## Docs
## https://developer.basespace.illumina.com/docs/content/documentation/cli/cli-overview
if [[ ! -d $HOME/tools/ ]]; then mkdir -p $HOME/tools/; done
wget "https://launch.basespace.illumina.com/CLI/latest/amd64-linux/bs" -O $HOME/tools/basespace
chmod u+x $HOME/tools/basespace
./basespace auth
### follow path to website and sign in
### should display "Welcome [name of user]
```
---

## **Reproducibility**
To ensure **consistent results**, specify the pipeline version when running:

```bash
nextflow run ODHL/ODHL_AR -r 1.0.0
```

You can check for the latest version on the **[ODHL/ODHL_AR GitHub Releases page](https://github.com/ODHL/ODHL_AR/releases/)**.

---