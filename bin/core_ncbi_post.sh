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

#########################################################
# project variables
#########################################################
#set year
year="2025"

# set date
date_stamp=`date '+%Y_%m_%d'`

##########################################################
# Set files, dir
#########################################################
# prep files
ncbi_results="srr_db_results.csv"

# pull the ncbi dir 
cachedDB_file=${today}_srr_db.csv

#########################################################
# Controls
#########################################################

#########################################################
# Code
#########################################################
# NCBI Post
echo "sampleID,WGSID,SRRID,SAMID,PROJECTID" > $ncbi_results

# copy the original file to the backup
cp $ncbiDB_file srr_db_backup.csv

# copythe original file to the cache
cp $ncbiDB_file $cachedDB_file

# process samples
counter=1
sample_list=($(cut -d',' -f1 $sample_list))
for sample_id in "${sample_list[@]}"; do
	if [[ $sample_id == *ODHL_sample* ]]; then
		echo "$sample_id,${year}ZN-999$counter,SRAfakeID$counter,SAMNfakeID$counter,$project_id" >> $ncbi_results
		counter=$((counter+1))
	else
		# add the file info to the master database
		wgsID=`cat $wgsDB_file | grep $sample_id | awk -F"," '{print $2}'`
		sraID=`cat $ncbi_output | grep $wgsID | awk '{print $1}'`
		samID=`cat $ncbi_output | grep $wgsID | awk '{print $5}'`

		if [[ $sraID == "" ]]; then 
			sraID=`cat $ncbiDB_file | grep $wgsID | awk '{print $1}'`
			samID=`cat $ncbiDB_file | grep $wgsID | awk '{print $3}'`
		else
			# add to final output
			echo "$sample_id,$wgsID,$sraID,$samID,$project_id" >> $cachedDB_file
		fi

		# add the information to the project specific file
		echo "$sample_id,$wgsID,$sraID,$samID,$project_id" >> $ncbi_results
	fi
done
    
# cp the cache to the master file
cat $cachedDB_file | sort | uniq > $ncbiDB_file