# bash bin/core_wgs_id.sh phoenix_results.sh labResults.csv

#########################################################
# ARGS
#########################################################
project_id=$1
ncbiDB_file=$2
wgsDB_file=$3
sample_list=$4

##########################################################
# Eval, source
#########################################################

##########################################################
# Set files, dir
#########################################################
# prep files
ncbi_results="ncbi_resultIDs.csv"

# pull the ncbi dir 
ncbi_dir=$(dirname "$ncbiDB_file")
cachedDB_file="${ncbi_dir}/cached/${date_stamp}_upload_db.csv"

#########################################################
# project variables
#########################################################
#set year
year="2025"

# set date
date_stamp=`date '+%Y_%m_%d'`

#########################################################
# Controls
#########################################################

#########################################################
# Code
#########################################################
# NCBI Post
echo "WGSID,SRRID,SAMID" > $ncbi_results

# copy the original file to the backup
cp $ncbiDB_file $ncbi_dir/srr_db_backup.csv

# copythe original file to the cache
cp $ncbiDB_file $cachedDB_file

# process samples
IFS=$'\n' read -d '' -r -a sample_list < $sample_list
for id in "${sample_list[@]}"; do

	# add the file info to the master database
	wgsID=`cat $wgsDB_file | grep $id | awk -F"," '{print $2}'`
	sraID=`cat $ncbi_output | grep $wgsID | awk '{print $1}'`
	samID=`cat $ncbi_output | grep $wgsID | awk '{print $5}'`

	if [[ $sraID == "" ]]; then 
		sraID=`cat $ncbiDB_file | grep $wgsID | awk '{print $1}'`
		samID=`cat $ncbiDB_file | grep $wgsID | awk '{print $3}'`
	else
		# add to final output
		echo "$sraID,$wgsID,$samID,$project_id" >> $cachedDB_file
	fi

	# add the information to the project specific file
	echo "$wgsID,$sraID,$samID" >> $ncbi_results
done
    
# cp the cache to the master file
cat $cachedDB_file | sort | uniq > $ncbiDB_file