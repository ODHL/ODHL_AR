# bash bin/core_wgs_id.sh phoenix_results.sh labResults.csv

#########################################################
# ARGS
#########################################################
project_id=$1
idDB_file=$2
ncbi_pre_file=$3
ncbi_output_file=$4
##########################################################
# Eval, source
#########################################################

#########################################################
# project variables
#########################################################
#set year
year="2025"

##########################################################
# Set files, dir
#########################################################
# prep files
id_dir=$(dirname "$idDB_file")
id_log="id_db_log.txt"

# create cache dir
today=`date +%Y%m%d`
cachedDB_file=${today}_id_db.csv
cp $idDB_file $cachedDB_file

# update the ID results file to include SRR
ncbi_post_file="id_db_results_postNCBI.csv"
cp $ncbi_pre_file $ncbi_post_file

#########################################################
# Controls
#########################################################

#########################################################
# Code
#########################################################
# process samples by wgsID
awk -F"," '{print $3}' $ncbi_pre_file > passed_samples
IFS=$'\n' read -d '' -r -a sample_list < passed_samples
echo "" >> $cachedDB_file
for wgsID in "${sample_list[@]}"; do
    echo "--sample: $wgsID" >> $id_log

	# check if the sample was uploaded
	check=`cat $ncbi_output_file | grep $wgsID`

	# update ID's with NCBI information
	if [[ $check == "" ]]; then
		echo "----sample not uploaded" >> $id_log
	else
		# grab sample_id, srrID, samID
		sample_id=`cat $ncbi_post_file | grep $wgsID | awk -F"," '{print $2}'` 
		srrID=`cat $ncbi_output_file | grep $wgsID | awk -F"\t" '{print $1}'` 
		samID=`cat $ncbi_output_file | grep $wgsID | awk -F"\t" '{print $5}'`

		# update post file
		sed -i "s/$wgsID,,,/$wgsID,$srrID,$samID,/g" $ncbi_post_file

		# Add data to the cacheDB, as long as it's not a test sample
		if [[ $sample_id == "ODHL_sample4" ]]; then
			echo "test passes: $project_id,$sample_id,$wgsID,$srrID,$samID,$today" >> $id_db_log
		else
			echo "----$sample_id added to cache" >> $id_db_log
			echo "$project_id,$sample_id,$wgsID,$srrID,$samID,$today" >> $cachedDB_file
		fi
	fi
done

# copy the master to backup  
cat $idDB_file | uniq > $id_dir/id_db_backup.csv

# copy the new file to master
cat $cachedDB_file | uniq > $id_dir/id_db_master.csv

# copy the cached file to the directory
cp $cachedDB_file $id_dir/cached