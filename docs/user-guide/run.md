
# Run the Pipeline
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