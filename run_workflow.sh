#!/bin/bash
# Author: S Chill
# Date: 1/20/2025
# bash run_workflow.sh -p all -i test

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
   echo "Usage: $1 -e [REQUIRED] entry"
   echo -e "\t-e options: arBASESPACE,arANALYSIS,arPOST,outbreakANALYSIS,outbreakREPORTING,NFCORE_OUTBREAK"
   echo "Usage: $2 -i [REQUIRED] project_id"
   echo -e "\t-i project id"
   echo "Usage: $3 -r [OPTIONAL] resume_run"
   echo -e "\t-r Y,N option to resume a partial run settings (default Y)"
   echo "Usage: $4 -o [OPTIONAL] outbreakReport"
   echo -e "\t-o basic, advanced"
   echo "Usage: $5 -n [OPTIONAL] nextflowParams"
   echo -e "\t-n any nextflow configs (default --max_memory 7.GB --max_cpus 4)"
   exit 1 # Exit script after printing help
}
while getopts "e:i:r:o:n:" opt
do
   case "$opt" in
      e ) entry="$OPTARG" ;;
      i ) project_id="$OPTARG" ;;
      r ) resume="$OPTARG" ;;
      o ) outbreakReport="$OPTARG" ;;
      n ) nextflowParams="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$entry" ] || [ -z "$project_id" ]; then
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
today_date=$(date '+%Y-%m-%d'); today_date=`echo $today_date | sed "s/-//g"`

# set optional nextflow ARGS
if [ -z "$nextflowParams" ]; then 
   nextflowParams="-profile docker,test --max_memory 7.GB --max_cpus 4"
fi

# determine entry flag
if [ $entry == "arPOST" ]; then entry="arANALYSIS --ncbiProcess TRUE"; fi

#set defaults for optional resume
if [ -z "$resume" ]; then nextflowParams="-resume $nextflowParams"; fi

# set output dir, tmp dir
outDir="/home/ubuntu/output/$project_name"
if [[ ! -d $outDir/tmp ]]; then mkdir -p $outDir/tmp; fi

# arBASESPACE
#all,analyze,dbUpload,dbPost,outbreakAnalyze,outbreakReport"
cmd="nextflow run \
   main.nf \
   $nextflowParams \
   -entry $entry \
   --outdir $outDir \
   --projectID $project_name \
   -work-dir $outDir/tmp"
echo $cmd
$cmd