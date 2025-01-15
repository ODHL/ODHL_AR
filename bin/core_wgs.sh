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
wgs_db_master=$3
wgs_results=$4

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
# read in final report; create sample list
IFS=$'\n' read -d '' -r -a sample_list < $phoenix_results

# create cache of local
today=`date +%Y%m%d`
cached_db=${today}_wgs_db.csv
cp $wgs_db_master $cached_db
# cp $wgs_dir/wgs_db_master.csv $cached_db

# add a new line
echo "" >> $cached_db

# add header
echo "sampleID,wgsID" > $wgs_results

# for first sample, check ID file
first_grab="Y"

for sample_id in ${sample_list[@]}; do
#         if [[ $sample_id != "ID" ]] && [[ $sample_id != *"SRR"* ]]; then
#             sample_id=$(clean_file_names $sample_id)
#             echo "--sample: $sample_id"

#             # check the QC status of the sample
#             check=`cat $pipeline_results | grep $sample_id | cut -f2 -d";" | sort | uniq`

#             # if the sample passed QC, assign a WGS ID
#             if [[ $check == "PASS" ]]; then

#                 # then, check if sample already has an ID
#                 check=`cat $cached_db | grep "$sample_id"`

#                 # if the check passes, add new ID
#                 if [[ $check == "" ]]; then
#                     echo "----assigning new ID"

#                     # determine final ID assigned
#                     # WGSID,CGR_ID,projectID,DATE_ASSIGNED
#                     # YYYY-GZ-0001
#                     if [[ $first_grab == "Y" ]]; then
#                         echo "----pulling ID from cache"
#                         sed -i '/^$/d' $cached_db
#                         last_saved_id=`tail -n1 $cached_db | awk -F"," '{print $1}' | cut -f2 -d"-"`
#                         echo "----last saved: $last_saved_id"
#                         stripped_id=`echo "${last_saved_id#"${last_saved_id%%[!0]*}"}"`
#                         echo "----stripped $stripped_id"
#                         new_id=$(( stripped_id + 1 ))
#                         first_grab="N"
#                     fi

#                     # add zeros so the final ID is always four digits
#                     if [[ $new_id -lt 10 ]]; then
#                         final_id="2024ZN-000$new_id"
#                     elif [[ $new_id -lt 100 ]]; then
#                         final_id="2024ZN-00$new_id"
#                     elif [[ $new_id -lt 1000 ]]; then
#                         final_id="2024ZN-0$new_id"
#                     else
#                         final_id="2024ZN-$new_id"
#                     fi

#                     # add sample with new ID to list
#                     add_line="$final_id,$sample_id,$project_name,$today"
#                     echo $add_line >> $cached_db
#                     echo -e "$sample_id,$final_id" >> $wgs_results
                    
#                     #increase counter
#                     new_id=$(( new_id + 1 ))
#                 else
#                     echo "----sample was already assigned an ID: $check"
#                     final_id=`echo $check |cut -f1 -d","`
#                     echo -e "$sample_id,$final_id" >> $wgs_results
#                 fi
#             elif [[ $check == "FAIL" ]]; then
#                 echo "---- Pipe $check"
#                 echo -e "$sample_id,NO_ID" >> $wgs_results
#             elif [[ $check == "" ]]; then
#                 echo "---- Seq FAIL"
#                 echo -e "$sample_id,NO_ID" >> $wgs_results
#             else
#                 echo "Something is wrong"
#                 echo "--$check"
#             fi
#         fi
#     done

#     # create new copy
#     sed -i '/^$/d' $cached_db
#     cp $wgs_dir/wgs_db_master.csv $wgs_dir/wgs_db_backup.csv
#     cp $cached_db $wgs_dir/wgs_db_master.csv
#     mv $cached_db $wgs_dir/cached
# fi