#!/bin/bash


#############################################################################################
# Background documentation
#############################################################################################
# Basespace
# https://developer.basespace.illumina.com/docs/content/documentation/cli/cli-examples#Downloadallrundata

#Docker location
# https://hub.docker.com/u/staphb


#############################################################################################
# functions
#############################################################################################

helpFunction()
{
   echo ""
   echo "Usage: $1 -p [REQUIRED] pipeline runmode"
   echo -e "\t-p options: phase1, phase2, init, analysis, wgs, ncbi_upload, ncbi_download, report, cleanup"
   echo "Usage: $2 -n [REQUIRED] project_id"
   echo -e "\t-n project id"
   echo "Usage: $4 -r [OPTIONAL] resume_run"
   echo -e "\t-r Y,N option to resume a partial run settings (default N)"

   exit 1 # Exit script after printing help
}

while getopts "p:n:s:r:t:m:o:" opt
do
   case "$opt" in
        p ) pipeline="$OPTARG" ;;
        n ) project_id="$OPTARG" ;;
       	r ) resume="$OPTARG" ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$pipeline" ] || [ -z "$project_id" ]; then
   echo "Some or all of the parameters are empty";
   helpFunction
fi
#############################################################################################
# args
#############################################################################################
# Remove trailing / to project_name if it exists
# some projects may have additional information (IE OH-1234 SARS ONLY) in the name
# To avoid issues within project naming schema remove all information after spaces
# To ensure consistency in all projects, remove all information after _
project_name_full=$(echo $project_id | sed 's:/*$::')
project_name=$(echo $project_id | cut -f1 -d "_" | cut -f1 -d " ")

# set date
proj_date=`echo 20$project_name | sed 's/OH-[A-Z]*[0-9]*-//' | sed "s/_SARS//g"`
today_date=$(date '+%Y-%m-%d'); today_date=`echo $today_date | sed "s/-//g"`


outDir="/home/ubuntu/output/$project_name"
if [[ ! -d $outDir/tmp ]]; then mkdir -p $outDir/tmp; fi

#set defaults for optional resume
if [ -z "$resume" ]; then resume="N"; fi

if [[ $pipeline == "run" ]]; then
    nextflow run \
        /home/ubuntu/workflows/ODHL_AR/main.nf \
         -resume \
        -profile docker,test \
        -entry NFCORE_ODHLAR \
        --max_memory 7.GB \
        --max_cpus 4 \
        --outdir $outDir \
        --projectID $project_name \
        -work-dir $outDir/tmp
fi
