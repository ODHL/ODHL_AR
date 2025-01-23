# bash bin/core_wgs_id.sh phoenix_results.sh labResults.csv

#########################################################
# ARGS
#########################################################
core_functions=$1
sample_list=$2
wgsDB_file=$3

##########################################################
# Eval, source
#########################################################
source $(dirname "$0")/core_functions.sh

##########################################################
# Set files, dir
#########################################################
# pull the WGS dir 
wgs_dir=$(dirname "$wgsDB_file")
wgs_results="wgs_db_results.csv"
wgs_log="wgs_db_log.csv"

#########################################################
# project variables
#########################################################
year="2025"

##########################################################
# Run code
#########################################################
# create cache of local
today=`date +%Y%m%d`
cachedDB_file=${today}_wgs_db.csv
cp $wgsDB_file $cachedDB_file

# add a new line
echo "" >> $cachedDB_file

# prepare a new WGS file
echo "sampleID,wgsID" > $wgs_results

# for each sample, check ID file
first_grab="Y"
sample_list=($(cut -d',' -f1 $sample_list))

# handle test data, which should not be added to the DB
counter=1
for sample_id in ${sample_list[@]}; do
    if [[ $sample_id == *ODHL_sample* ]]; then
        echo -e "$sample_id,${year}ZN-999$counter" >> $wgs_results
        counter=$((counter+1))
    else
        if [[ $sample_id != "ID" ]]; then
            echo "--sample: $sample_id">> $wgs_log
            
            #clean the sampleID
            clean_id=$(clean_file_names $sample_id)
            
            # check if sample already has an ID
            check=`cat $cachedDB_file | grep "$clean_id"`

            # if the check is empty, add new ID
            if [[ $check == "" ]]; then
                echo "----assigning new ID">> $wgs_log

                # determine final ID assigned
                # WGSID,CGR_ID,projectID,DATE_ASSIGNED
                # YYYY-GZ-0001
                if [[ $first_grab == "Y" ]]; then
                    echo "----pulling ID from cache" >> $wgs_log
                    sed -i '/^$/d' $cachedDB_file
                    last_saved_id=`tail -n1 $cachedDB_file | awk -F"," '{print $1}' | cut -f2 -d"-"`
                    echo "----last saved: $last_saved_id" >> $wgs_log
                    stripped_id=`echo "${last_saved_id#"${last_saved_id%%[!0]*}"}"`
                    echo "----stripped $stripped_id" >> $wgs_log
                    new_id=$(( stripped_id + 1 ))
                    first_grab="N"
                fi

                # add zeros so the final ID is always four digits
                if [[ $new_id -lt 10 ]]; then
                    final_id="${year}ZN-000$new_id"
                elif [[ $new_id -lt 100 ]]; then
                    final_id="${year}ZN-00$new_id"
                elif [[ $new_id -lt 1000 ]]; then
                    final_id="${year}ZN-0$new_id"
                else
                    final_id="${year}ZN-$new_id"
                fi

                # add sample with new ID to list
                add_line="$final_id,$sample_id,$project_name,$today"
                echo $add_line >> $cachedDB_file
                echo -e "$sample_id,$final_id" >> $wgs_results
                
                #increase counter
                new_id=$(( new_id + 1 ))
            else
                echo "----sample was already assigned an ID: $check">> $wgs_log
                final_id=`echo $check |cut -f1 -d","`
                echo -e "$sample_id,$final_id" >> $wgs_results
            fi
        elif [[ $check == "FAIL" ]]; then
            echo "---- Pipeline failure $check">> $wgs_log
            echo -e "$sample_id,NO_ID" >> $wgs_results
        elif [[ $check == "" ]]; then
            echo "---- Seq failure $check">> $wgs_log
            echo -e "$sample_id,NO_ID" >> $wgs_results
        else
            echo "Something is wrong" $check>> $wgs_log
        fi
    fi
done

# copy the original file to the backup
sed -i '/^$/d' $cachedDB_file
cp $wgsDB_file $wgs_dir/wgs_db_backup.csv

# copy the new file to master
cp $cachedDB_file $wgs_dir/wgs_db_master.csv

# copy the cached file to the directory
cp $cachedDB_file $wgs_dir/cached