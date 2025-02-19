# bash bin/core_id_id.sh phoenix_results.sh labResults.csv

#########################################################
# ARGS
#########################################################
core_functions=$1
quality_file=$2
idDB_file=$3
project_id=$4

##########################################################
# Eval, source
#########################################################
source $(dirname "$0")/core_functions.sh

##########################################################
# Set files, dir
#########################################################
# pull the id dir 
id_dir=$(dirname "$idDB_file")
id_results="id_db_results.csv"
id_log="id_db_log.csv"

#########################################################
# project variables
#########################################################
year="2025"

##########################################################
# Run code
#########################################################
# create cache of local
today=`date +%Y%m%d`
cachedDB_file=${today}_id_db.csv
cp $idDB_file $cachedDB_file

# add a new line
echo "" >> $cachedDB_file

# pull sample files
cat $quality_file | awk -F"\t" '{print $1}' | grep -v "ID" | uniq > $processed_samples
IFS=$'\n' read -d '' -r -a sample_list < $processed_samples


# # prepare a new id file
# echo "sampleID,idID" > $id_results

# # for each sample, check ID file
# first_grab="Y"
# sample_list=($(cut -d',' -f1 $sample_list))

# # handle test data, which should not be added to the DB
# counter=1

# for sample_id in ${sample_list[@]}; do
#     if [[ $sample_id != "ID" ]]; then
#         echo "--sample: $sample_id">> $id_log
            
#         # clean the sampleID
#         clean_id=$(clean_file_names $sample_id)
            
#         # check if sample already has an ID
#         check=`cat $cachedDB_file | grep "$clean_id"`

#         # if the check is empty, add new ID
#         if [[ $check == "" ]]; then
#             echo "----assigning new ID">> $id_log

#             # determine final ID assigned
#             # PROJECT_ID,OHIO_ID,WGSID,SRRID,SAMID,DATE_ASSIGNED
#             # YYYY-GZ-0001
#             if [[ $first_grab == "Y" ]]; then
#                 echo "----pulling ID from cache" >> $id_log
#                 sed -i '/^$/d' $cachedDB_file
#                 last_saved_id=`tail -n1 $cachedDB_file | awk -F"," '{print $3}' | cut -f2 -d"-"`
#                 echo "----last saved: $last_saved_id" >> $id_log
#                 stripped_id=`echo "${last_saved_id#"${last_saved_id%%[!0]*}"}"`
#                 echo "----stripped $stripped_id" >> $id_log
#                 new_id=$(( stripped_id + 1 ))
#                 first_grab="N"
#             fi

#             # add zeros so the final ID is always four digits
#             if [[ $new_id -lt 10 ]]; then
#                 final_id="${year}ZN-000$new_id"
#             elif [[ $new_id -lt 100 ]]; then
#                 final_id="${year}ZN-00$new_id"
#             elif [[ $new_id -lt 1000 ]]; then
#                 final_id="${year}ZN-0$new_id"
#             else
#                 final_id="${year}ZN-$new_id"
#             fi

#             # add sample with new ID to list
#             # PROJECT_ID,OHIO_ID,WGSID,SRRID,SAMID,DATE_ASSIGNED
#             add_line="$project_id,$sample_id,$final_id,,,$today"
#             echo $add_line >> $cachedDB_file
#             echo -e "$add_line" >> $id_results
                
#             #increase counter
#             new_id=$(( new_id + 1 ))
#         else
#             echo "----sample was already assigned an ID: $check">> $id_log
#             final_id=`echo $check |cut -f1 -d","`
#             echo -e "$sample_id,$final_id" >> $id_results
#         fi
#     fi
# done

# # copy the original file to the backup
# sed -i '/^$/d' $cachedDB_file
# cp $idDB_file $id_dir/id_db_backup.csv

# # copy the new file to master
# cp $cachedDB_file $id_dir/id_db_master.csv

# # copy the cached file to the directory
# cp $cachedDB_file $id_dir/cached