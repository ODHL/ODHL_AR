
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
  -p <pipelineRunmode> \ #REQUIRED: all,analyze,dbUpload,dbPost,outbreakAnalyze,outbreakReport
  -i <projectID> \ #REQUIRED: test
  -r <resumeRun> \ #OPTIONAL: Y,N (default Y)
  -o <outbreakReportFlag> #OPTIONAL: basic, advanced
  -n <nextflowParams> #OPTIONAL: nextflow configs (default -profile docker,test -entry NFCORE_ODHLAR --max_memory 7.GB --max_cpus 4)
```
