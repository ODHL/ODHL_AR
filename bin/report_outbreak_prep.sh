#!/bin/bash

#########################################################
# ARGS
#########################################################
configFILE=$1
analyzer_results=$2
CFSAN_snpMatrix=$3
IQTREE_genomeTree=$4
ROARY_coreGenomeStats=$5
ar_predictions=$6
outbreak_metadata=$7
projectID=$8
outbreak_RMD=$9

##########################################################
# Eval, source
#########################################################

#########################################################
# Set dirs, files, args
#########################################################

##########################################################
# update variables
#########################################################
# set date
today=`date +%Y%m%d`

##########################################################
# Run analysis
#########################################################    
# prepare the report
sed -i "s/REP_CONFIG/$configFILE/g" $outbreak_RMD
sed -i "s/REP_SAMPLETABLE/$analyzer_results/g" $outbreak_RMD
sed -i "s/REP_SNPMATRIX/$CFSAN_snpMatrix/g" $outbreak_RMD
sed -i "s/REP_IQTREE/$IQTREE_genomeTree/g" $outbreak_RMD
sed -i "s/REP_CGSTATS/$ROARY_coreGenomeStats/g" $outbreak_RMD
sed -i "s~REP_PREDICT~$ar_predictions~g" $outbreak_RMD
sed -i "s~REP_META~$outbreak_metadata~g" $outbreak_RMD
sed -i "s/REP_OB/$projectID/g" $outbreak_RMD
sed -i "s~REP_DATE~$today~g" $outbreak_RMD