# bash bin/core_wgs_id.sh /home/ubuntu/output/OH-VH00648-230526/pipeline/batch_1 OH-VH00648-230526
#########################################################
# ARGS
#########################################################
# output_dir=$1
# project_name_full=$2
# wgs_results=$3
# pipeline_results=$4
# pipeline_log=$5

core_functions=$1
phoenix_results=$2

##########################################################
# Eval, source
#########################################################
source $(dirname "$0")/$core_functions

# ##########################################################
# # Set files, dir
# #########################################################
# wgs_dir="/home/ubuntu/workflows/AST_Workflow/wgs_db"

# #########################################################
# # project variables
# #########################################################
# # set project shorthand
# project_name=$(echo $project_name_full | cut -f1 -d "_" | cut -f1 -d " ")

##########################################################
# Run code
#########################################################
# convert format
cp $phoenix_results pipeline_results.csv
sed -i "s/\t/;/g" pipeline_results.csv

# review synopsis and determine status
cat pipeline_results.csv | awk -F";" '{print $1}' | grep -v "ID" | uniq > processed_samples.csv
IFS=$'\n' read -d '' -r -a sample_list < processed_samples.csv

for sample_id in "${sample_list[@]}"; do
	# process all samples
	echo $sample_id
		
	# pull only ID
	clean_id=$(clean_file_names $sample_id)

	# pull stats
	cat ${sample_id}_trimmed_read_counts.txt >> all_trimmed_read_counts.txt #stats.txt

	# determine number of warnings, fails
	synopsis=$log_dir/pipeline/$sample_id.synopsis
	num_of_warnings=`cat $synopsis | grep -v "WARNINGS" | grep "WARNING" | wc -l`
	num_of_fails=`cat $synopsis | grep -v "completed as FAILED" | grep "FAILED" | wc -l`

		# # review lab results
		# labValue=`cat $lab_results | grep $sample_id | cut -f2 -d";" | sort | awk '{print $1}'`
		# pipelineValue=`cat $phoenix_results | grep $sample_id | awk -F"\t" '{print $9}' | sort | awk '{print $1}'`
		# pipelineStatus=`cat $phoenix_results | grep $sample_id | awk -F"\t" '{print $2}'`
		
		# # message if the lab didnt give results
		# if [[ $labValue == "" ]]; then echo "Missing lab value: $sample_id"; fi

		# # update the results and reasons
		# SID=$(awk -F"\t" -v sid=$sample_id '{ if ($1 == sid) print NR }' $phoenix_results)
		# if [[ $num_of_warnings -gt 4 ]]; then
		# 	echo "--fail: exceeds warnings"
		# 	reason=$(cat $synopsis | grep -v "Summarized" | grep -E "WARNING|FAIL" | awk -F": " '{print $3}' |  awk 'BEGIN { ORS = "; " } { print }' | sed "s/; ; //g")
		# 	cat pipeline_results.csv | awk -F";" -v i=$SID -v reason="${reason}" 'BEGIN {OFS = FS} NR==i {$2="FAIL"; $24=reason}1' > tmp; mv tmp pipeline_results.csv
		# else
		# 	if [[ $pipelineStatus == "PASS" && *"$pipelineValue" != *"$labValue"*  ]]; then
		# 		reason="Lab Discordance"
		# 		cat pipeline_results.csv | awk -F";" -v i=$SID -v reason="${reason}" 'BEGIN {OFS = FS} NR==i {$2="FAIL"; $24=reason}1' > tmp; mv tmp pipeline_results.csv
		# 		echo "***"
		# 		echo "FAILED: discordance found $pipelineValue versus $labValue"
		# 		echo "***"
		# 	else
		# 		echo "--pass"
		# 	fi
		# fi

		# # set MLST scheme
		# species=`cat pipeline_results.csv | grep $sample_id | awk -F";" '{print $9}' | sort | uniq`
        # MLST_1=`cat pipeline_results.csv | grep $sample_id | awk -F";" '{print $16}' | sort | uniq | cut -f1 -d","`
        # MLST_Scheme_1=`cat pipeline_results.csv | grep $sample_id | awk -F";" '{print $15}' | sort | uniq`
        # MLST_2=`cat pipeline_results.csv | grep $sample_id | awk -F";" '{print $18}'| sort | uniq | cut -f1 -d","`
        # MLST_Scheme_2=`cat pipeline_results.csv | grep $sample_id | awk -F";" '{print $17}'| sort | uniq`

		# # handle schemes that have parenthesis
        # if [[ $MLST_Scheme_1 =~ "(" ]]; then MLST_Scheme_1=`echo $MLST_Scheme_1 | sed -E -n 's/.*\((.*)\).*$/\1/p'`; fi
        # if [[ $MLST_Scheme_2 =~ "(" ]]; then MLST_Scheme_2=`echo $MLST_Scheme_2 | sed -E -n 's/.*\((.*)\).*$/\1/p'`; fi

        # # check if the first scheme exists
		# if [[ $MLST_1 == "-" ]] || [[ $MLST_1 == *"Novel"* ]]; then
        #     sequence_classification="MLST__${species}"
        # else
		# 	# check if there is a second MLST
		# 	if [[ $MLST_2 == "-" ]]; then
		# 		sequence_classification=`echo "ML${MLST_1}_${MLST_Scheme_1}_${species}"`
		# 	else
		# 		sequence_classification=`echo "ML${MLST_1}_${MLST_Scheme_1}_${species}-ML${MLST_2}_${MLST_Scheme_2}_${species}"`
		# 	fi
        # fi
		
		# # Add MLST
		# awk -v add="$sequence_classification;$labValue" -v sample="$sample_id" '$0 ~ sample {print $0";"add}' "pipeline_results.csv" >> "$mlst_file"
done






# # read in final report; create sample list
# IFS=$'\n' read -d '' -r -a sample_list < $phoenix_results

# 	# create copy of results
# 	cd $pipeline_dir
# 	mlst_file=mlst_output.csv
# 	if [[ -f $mlst_file ]]; then rm $mlst_file; fi

	
	

# 	# cleanup
# 	cat $mlst_file | sort | uniq > pipeline_results.csv
