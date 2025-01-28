# Author: S Sevilla
# Date: 1/20/2025
# Version: 1.0

# bash core_ncbi_prep.sh \
# bin/core_functions.sh \ #core_functions
# test \ #project_id
# test/metaData_NCBI.csv \ #metadata_file
# conf/ncbiConfig.yaml \ #ncbiConfig
# assets/databases/ncbi/srr_db_master.csv #ncbiDB_file
# ch_sample_list #sample_list
# ch_pipe_results #pipeline_results
# ch_wgs_results #wgsDB_file

#########################################################
# ARGS
#########################################################
core_functions=$1
project_id=$2
metadata_file=$3
ncbiConfig=$4
ncbiDB_file=$5
sample_list=$6
pipeline_results=$7
wgsDB_file=$8

##########################################################
# Eval, source
#########################################################
source $(dirname "$0")/core_functions.sh
eval $(parse_yaml ${ncbiConfig} "config_")

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
prep_pass="prep_pass.txt"
ncbi_upload="ncbi_sample_list.csv"
ncbi_attributes=batched_ncbi_att_${project_id}_${date_stamp}.tsv
ncbi_metadata=batched_ncbi_meta_${project_id}_${date_stamp}.tsv

# prepare the input dir
upload_dir="upload_dir"
mkdir -p $upload_dir

#########################################################
# Controls
#########################################################
flag_prep="Y"
flag_precheck="Y"

#########################################################
# Code
#########################################################
# NCBI Prep
if [[ $flag_prep == "Y" ]]; then

	sample_list=($(cut -d',' -f1 $sample_list))
	for id in "${sample_list[@]}"; do
        echo "--sample: $sample_id"
    
        # clean the sampleID, grab wgsID
        clean_id=$(clean_file_names $sample_id)
        wgs_id=`cat $wgsDB_file | grep $clean_id | cut -f1 -d","`
        
        # check the old ncbi file to make sure it hasnt been updated
		srr_old=`cat $ncbiDB_file | grep $wgs_id | cut -f3 -d","` 
		if [[ $srr_old == "" ]]; then
			echo "NEW SAMPLE: $clean_id ($wgs_id)"
			echo $clean_id >> $ncbi_upload
		else
			echo "SRR already exists: $srr_old ($clean_id)"
		fi
	done
	
	# Create manifest for attribute upload
	chunk1="*sample_name\tsample_title\tbioproject_accession\t*organism\tstrain\tisolate\thost"
	chunk2="isolation_source\t*collection_date\t*geo_loc_name\t*sample_type\taltitude\tbiomaterial_provider\tcollected_by\tculture_collection\tdepth\tenv_broad_scale"
	chunk3="genotype\thost_tissue_sampled\tidentified_by\tlab_host\tlat_lon\tmating_type\tpassage_history\tsamp_size\tserotype"
	chunk4="serovar\tspecimen_voucher\ttemp\tdescription\tMLST"
	echo -e "${chunk1}\t${chunk2}\t${chunk3}\t${chunk4}" > $ncbi_attributes

	# Create manifest for metadata upload
	chunk1="sample_name\tlibrary_ID\ttitle\tlibrary_strategy\tlibrary_source\tlibrary_selection"
	chunk2="library_layout\tplatform\tinstrument_model\tdesign_description\tfiletype\tfilename"
	chunk3="filename2\tfilename3\tfilename4\tassembly\tfasta_file"
	echo -e "${chunk1}\t${chunk2}\t${chunk3}" > $ncbi_metadata

	# process samples
	IFS=$'\n' read -d '' -r -a sample_list < $ncbi_upload
	for id in "${sample_list[@]}"; do
		# set variables from wgsDB_file
		wgsID=`cat $wgsDB_file | grep $id | cut -f1 -d","`
		SID=$(awk -F";" -v sid=$id '{ if ($1 == sid) print NR }' $pipeline_results)
		organism=`cat $pipeline_results | awk -F"\t" -v i=$SID 'FNR == i {print $14}' | sed "s/([0-9]*.[0-9]*%)//g" | sed "s/  //g"`
			
		# grab metadata line
		meta=`cat $metadata_file | grep "$id"`

		#if meta is found create input metadata row
		if [[ ! "$meta" == "" ]]; then
			#convert date to ncbi required format - 4/21/81 to 1981-04-21
			raw_date=`echo $meta | grep -o "[0-9]*/[0-9]*/202[0-9]*"`
			collection_yr=`echo "${raw_date}" | awk '{split($0,a,"/"); print a[3]}' | tr -d '"'`

			# set title
			sample_title=`echo "Illumina Sequencing of ${wgsID}"`
				
			# pull source
			isolation_source=`echo $meta | awk -F"," '{print $11}'`

			# pull instrument
			instrument_model=`echo $project_id | cut -f2 -d"-"| grep -o "^."`
			if [[ $instrument_model == "M" ]]; then instrument_model="Illumina MiSeq"; else instrument_model="NextSeq 1000"; fi

			# get MLST
			MLST=`cat $pipeline_results | grep $id | awk -F"\t" '{print $25}'`

			# break output into chunks
			chunk1="${wgsID}\t${sample_title}\t${config_bioproject_accession}\t${organism}\t${config_strain}\t${wgsID}\t${config_host}"
			chunk2="${isolation_source}\t${collection_yr}\t${config_geo_loc_name}\t${config_sample_type}\t${config_taltitude}"
			chunk3="${config_biomaterial_provider}\t${config_tcollected_by}\t${config_culture_collection}\t${config_depth}"
			chunk4="${config_env_broad_scale}\t${config_genotype}\t${config_host_tissue_sampled}\t${config_identified_by}"
			chunk5="${config_lab_host}\t${config_lat_lon}\t${config_mating_type}\t${config_passage_history}\t${config_samp_size}"
			chunk6="${config_serotype}\t${config_serovar}\t${config_specimen_voucher}\t${config_temp}\t${config_description}\t${MLST}"
				
			# add output variables to attributes file
			echo -e "${chunk1}\t${chunk2}\t${chunk3}\t${chunk4}\t${chunk5}\t${chunk6}\t${chunk7}\t${chunk8}\t${chunk9}\t${chunk10}\t${chunk11}\t${chunk12}" >> $ncbi_attributes
			
			# breakoutput into chunks
			chunk1="${wgsID}\t${wgsID}\t${sample_title}\t${config_library_strategy}\t${config_library_source}\t${config_library_selection}"
			chunk2="${config_library_layout}\t${config_platform}\t${instrument_model}\t${config_design_description}\t${config_filetype}\t${id}.R1.fastq.gz"
			chunk3="${id}.R2.fastq.gz\t${config_filename3}\t${config_filename4}\t${assembly}\t${config_fasta_file}"

			# add output variables to attributes file
			echo -e "${chunk1}\t${chunk2}\t${chunk3}" >> $ncbi_metadata

            # set the FQ
            R1="$id*R1*"
			R2="$id*R2*"

			# check R1
			if [[ ! -f "$upload_dir/$id*R1*" ]]; then cp $R1 $upload_dir; else echo "MISSING FASTQ FILE: $R1"; fi

			# check R2
			if [[ ! -f "$upload_dir/$id*R2*" ]]; then cp $R2 $upload_dir; else echo "MISSING FASTQ FILE: $R2"; fi

        else
			echo "Missing metadata $id"
	    fi
    done
fi

# NCBI verify the prep is correct
if [[ "$flag_precheck" == "Y" ]]; then

	# process samples
	IFS=$'\n' read -d '' -r -a sample_list < $ncbi_upload
	for id in "${sample_list[@]}"; do
	
        # check FASTQ is in dir
        R1=`ls $upload_dir | grep $id | grep R1`
        R2=`ls $upload_dir | grep $id | grep R2`
        if [[ $R1 == "" ]] || [[ $R2 == "" ]]; then echo "----$id R1/R2 Error"; exit; fi
			
		# check ID is in attributes and metadata
		wgsID=`cat $wgsDB_file | grep $id | awk -F"," '{print $2}'`
		att=`cat $ncbi_attributes | grep $wgsID`
		meta=`cat $ncbi_metadata | grep $wgsID`
		if [[ $att == "" ]] || [[ $meta == "" ]]; then echo "----$id ATT/META Error"; exit; fi
	done
	
    echo "-----READY FOR UPLOAD" > $prep_pass
	echo "$upload_dir"
fi