#########################################################
# ARGS
#########################################################
# output_dir=$1
# project_name_full=$2
# pipeline_results=$3
# wgs_results=$4
# subworkflow=$5
# pipeline_config=$6
# pipeline_log=$7
core_functions=$1
basic_RMD=$2
project_id=$3
pipeline_results=$4
ncbiDB_file=$5
wgsDB_file=$6
##########################################################
# Eval, source
#########################################################
source $(dirname "$0")/core_functions.sh

#########################################################
# Set dirs, files, args
#########################################################
# log_dir=$output_dir/logs
# analysis_dir=$output_dir/analysis
# intermed_dir=$analysis_dir/intermed
# report_dir=$analysis_dir/reports

# sample_ids=$output_dir/logs/manifests/sample_ids.txt
# project_name=$(echo $project_name_full | cut -f1 -d "_" | cut -f1 -d " ")

final_results=final_report.csv
merged_prediction="ar_predictions.tsv"
# merged_snp="$intermed_dir/snp_distance_matrix.tsv"
# merged_tree="$intermed_dir/core_genome.tree"
# merged_cgstats="$intermed_dir/core_genome_statistics.txt"

# # set cmd
# analysis_cmd=$config_analysis_cmd
##########################################################
# Set flags
#########################################################
flag_prep="Y"
flag_basic="N"

##########################################################
# update reports
#########################################################
date_stamp=`date '+%Y_%m_%d'`
sed -i "s/REP_PROJID/$project_name/g" $basic_RMD
sed -i "s/REP_OB/$project_name/g" $basic_RMD
sed -i "s~REP_DATE~$todaysdate~g" $basic_RMD

##########################################################
# Run analysis
#########################################################    
if [[ $flag_prep == "Y" ]]; then
    # set results file
    chunk1="specimen_id,wgs_id,srr_id,wgs_date_put_on_sequencer,sequence_classification,run_id"
    chunk2="auto_qc_outcome,estimated_coverage,genome_length,species,mlst_scheme_1"
    chunk3="mlst_1,mlst_scheme_2,mlst_2,gamma_beta_lactam_resistance_genes"
    chunk4="auto_qc_failure_reason,lab_results,samn_id"
    echo -e "${chunk1},${chunk2},${chunk3},${chunk4}" > $final_results 
    
    # generate predictions file
    echo -e "Sample \tGene \tCoverage \tIdentity" > $merged_prediction

    # create final result file    
    sample_list=($(cat $pipeline_results | grep -v "sampleID" | awk -F"\t" '{print $1}'))
    for sample_id in "${sample_list[@]}"; do
        sample_id=$(clean_file_names $sample_id)
        cleanid=`echo $sample_id | cut -f1 -d"-"`

        # check WGS ID, if available
        if [[ $sample_id != *"SRR"* ]]; then
            wgsID=`cat $wgsDB_file | grep $sample_id | awk -F"," '{print $1}'`
            sraID=`cat $ncbiDB_file | grep $wgsID | awk -F"," '{print $3}'`
            samID=`cat $ncbiDB_file | grep $wgsID | awk -F"," '{print $4}'`
        else
            wgs_id="NO_ID"
            srr_number="$sample_id"
            samn_number="NO_ID"
        fi
        
        # set seq info
        wgs_date_put_on_sequencer=`echo $project_name | cut -f3 -d"-"`
        run_id=$project_name
        
        # determine row 
        SID=$(awk -F"\t" -v sid=$sample_id '{ if ($1 == sid) print NR }' $pipeline_results)
        SID=`echo $SID | cut -d" " -f1`

        # pull metadata
        Auto_QC_Outcome=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $2}'`
        Estimated_Coverage=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $4}'`
        Genome_Length=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $5}'`
        Auto_QC_Failure_Reason=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $24}'`

        # if samples fail due to seq (low reads), adjust
        if [[ $Auto_QC_Outcome == "" ]]; then Auto_QC_Outcome="SeqFAIL"; Auto_QC_Failure_Reason="sequencing_failure"; fi

        # pull analysis data
        Species=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $9}'| cut -f1 -d","`
        MLST_1=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $16}'| cut -f1 -d","`
        MLST_Scheme_1=`cat $pipeline_results | sort | uniq | awk -F"\t" -v i=$SID 'FNR == i {print $15}'`
        MLST_2=`cat $pipeline_results | sort | uniq | awk -F"\t" -v i=$SID 'FNR == i {print $18}'| cut -f1 -d","`
        MLST_Scheme_2=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $17}'`
        sequence_classification=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $25}'`
        GAMMA_Beta_Lactam_Resistance_Genes=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $19}'`
        
        # pull validation
        LabValidation=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $26}'`

        # prepare chunks
        chunk1="$sample_id,$wgs_id,$srr_number,$wgs_date_put_on_sequencer,\"${sequence_classification}\",$run_id"
        chunk2="$Auto_QC_Outcome,$Estimated_Coverage,$Genome_Length,"${Species}",$MLST_Scheme_1"
        chunk3="\"${MLST_1}\",$MLST_Scheme_2,\"${MLST_2}\",\"${GAMMA_Beta_Lactam_Resistance_Genes}\""
        chunk4="\"${Auto_QC_Failure_Reason}\",\"${LabValidation}\",\"${samn_number}\""
        echo -e "${chunk1},${chunk2},${chunk3},${chunk4}" >> $final_results
    	
        # create all genes output file
		if [[ $Auto_QC_Outcome == "PASS" ]]; then
            cat ${sample_id}_all_genes.tsv | awk -F"\t" '{print $2"\t"$6"\t"$16"\t"$17}' | sed -s "s/_all_genes.tsv//g" | grep -v "_Coverage_of_reference_sequence">> $merged_prediction
        fi
    done
fi