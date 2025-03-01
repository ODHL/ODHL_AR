# to build lists
for f in */analysis/reports/final_report.csv; do cat $f | grep "PASS" | grep "Pseudomonas" | awk -F"," '{print $1","$7","$6","$10}'>>pseudomonas.txt; done

# run nextflow
bash run_workflow.sh -e arANALYSIS -i pseudomonas \
-l /home/ubuntu/workflows/ODHL_AR/assets/databases/outbreak/pseudomonas/labResults.csv \
-n "--runBASESPACE TRUE -profile docker --max_memory 7.GB --max_cpus 4 --input /home/ubuntu/workflows/ODHL_AR/assets/databases/outbreak/pseudomonas/samplesheet_psedusomonas.csv"