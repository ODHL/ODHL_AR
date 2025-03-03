# create input directory
mkdir -p /home/ubuntu/output/<species_id>/input

# create the samplesheet.csv from the appropriate list
## assets/databases/outbreak/<species_id>/<species_id>.txt
## cp /home/ubuntu/workflows/ODHL_AR/assets/databases/outbreak/pseudomonas/samplesheet_<species_id>.csv /home/ubuntu/output/<species_id>/input

# create the labResults.csv from the appropriate list
## assets/databases/outbreak/<species_id>/<species_id>.txt
## cp /home/ubuntu/workflows/ODHL_AR/assets/databases/outbreak/pseudomonas/labResults_<species_id>.csv /home/ubuntu/output/<species_id>/input

# Run the arANALYSIS pipeline on the lists of samples
bash run_workflow.sh \
	-e arANALYSIS \
	-i <species_id> \
	-l /home/ubuntu/output/<species_id>/input/labResults_<species_id>.csv \
	-n "--runBASESPACE TRUE --input /home/ubuntu/output/<species_id>/input/samplesheet_<species_id>.csv -profile docker --max_memory 7.GB --max_cpus 4"

# move project files to the internal dir
## first species_id is the name of the output dir
## second species_id is the name of the destination dir
bash assets/databases/outbreak/files_source.sh <species_id> <species_id> 

# create alias id's for public viewing
# species_id refers to the second species_id above
bash assets/databases/outbreak/files_internal.sh <species_id>
