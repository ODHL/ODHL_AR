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
   echo -e "\t-e options: arBASESPACE,arANALYSIS,arFORMAT,arREPORT,outbreakANALYSIS"
   echo "Usage: $2 -i [REQUIRED] project_id"
   echo -e "\t-i project id"
   echo "Usage: $3 -n [OPTIONAL] nextflowParams"
   echo -e "\t-n any nextflow configs (default --max_memory 7.GB --max_cpus 4)"
   echo "Usage: $4 -r [OPTIONAL] resume_run"
   echo -e "\t-r Y,N option to resume a partial run settings (default Y)"
   echo "Usage: $5 -l [OPTIONAL] labResults"
   echo -e "\t-l path to the labResults file"
   echo "Usage: $6 -m [OPTIONAL] metadata_NCBI"
   echo -e "\t-m path to the labResults file"
   echo "Usage: $7 -o [OPTIONAL] output_NCBI"
   echo -e "\t-o path to the labResults file"
   echo "Usage: $8 -g [OPTIONAL] input_gff"
   echo -e "\t-g path to the sapmleList to run outbreak analysis"   
   exit 1 # Exit script after printing help
}
   # echo "Usage: $4 -o [OPTIONAL] outbreakReport"
   # echo -e "\t-o basic, advanced"
      # o ) outbreakReport="$OPTARG" ;;


while getopts "e:i:n:r:l:m:o:" opt
do
   case "$opt" in
      e ) entry="$OPTARG" ;;
      i ) project_id="$OPTARG" ;;
      n ) nextflowParams="$OPTARG" ;;
      r ) resume="$OPTARG" ;;
      l ) labResults="$OPTARG" ;;
      m ) metadata_NCBI="$OPTARG" ;;
      o ) output_NCBI="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$entry" ] || [ -z "$project_id" ]; then
   echo "Required -entry and/or -project_id parameters are empty";
   helpFunction
fi
#############################################################################################
# Required ARGS
#############################################################################################
# Remove trailing / to project_name if it exists
# some projects may have additional information (IE OH-1234 SARS ONLY) in the name
# To avoid issues within project naming schema remove all information after spaces
# To ensure consistency in all projects, remove all information after _
project_name_full=$(echo $project_id | sed 's:/*$::')
project_name=$(echo $project_id | cut -f1 -d "_" | cut -f1 -d " ")

# set date
today_date=$(date '+%Y-%m-%d'); today_date=`echo $today_date | sed "s/-//g"`

# set proj dir, output dir, tmp dir
projDir="$HOME/$project_name"
outDir="$projDir/results/$entry"
tmpDir="$projDir/tmp"
if [[ ! -d $tmpDir ]]; then mkdir -p $tmpDir; fi

#########################################################################################
## OPTIONAL ARGS
#########################################################################################
# set defaults for optional nextflow ARGS
if [ -z "$nextflowParams" ]; then 
   nextflowParams="-profile docker,test --max_memory 7.GB --max_cpus 4"
fi

# set defaults for optional resume
if [ -z "$resume" ]; then nextflowParams="-resume $nextflowParams"; fi

# arFORMATTER settings
if [[ $entry == "arFORMAT" ]]; then
   nextflowParams="$nextflowParams --analysis_outdir $projDir/results/arANALYSIS"
   
   # set labResults, if present
   if [ ! -z $labResults ]; then nextflowParams="$nextflowParams --labResults $labResults"; fi

   # set metadata_NCBI, if present
   if [ ! -z $metadata_NCBI ]; then nextflowParams="$nextflowParams --metadata_NCBI $metadata_NCBI"; fi

fi

# arREPORTER settings
if [[ $entry == "arREPORT" ]]; then
   nextflowParams="$nextflowParams --analysis_outdir $projDir/results/arANALYSIS --format_outdir $projDir/results/arFORMAT"

   # set output_NCBI, if present
   if [ ! -z $output_NCBI ]; then nextflowParams="$nextflowParams --output_NCBI $output_NCBI"; fi 
fi

# arOUTBREAK settings
if [[ $entry == "outbreakANALYSIS" ]]; then
   nextflowParams="$nextflowParams --analysis_outdir $projDir/results/arANALYSIS --report_outdir $projDir/results/arREPORT"

   # set output_NCBI, if present
   if [ ! -z $input_gff ]; then nextflowParams="$nextflowParams --input_gff $input_gff"; fi 
fi


#########################################################################################
## Command
#########################################################################################
# Run command
cmd="nextflow run \
   main.nf \
   $nextflowParams \
   -entry $entry \
   --outdir $outDir \
   --projectID $project_name \
   -work-dir $tmpDir"

echo; echo "Command Running:"
echo "$cmd"
$cmd
