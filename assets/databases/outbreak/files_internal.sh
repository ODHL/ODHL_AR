# set args
species_id=$1

# set dirs
source_dir="/home/ubuntu/workflows/ODHL_AR/assets/databases/outbreak/internal/$species_id"
dest_dir="/home/ubuntu/workflows/ODHL_AR/assets/databases/outbreak/$species_id"

# create the directories
if [[ -d $dest_dir/gff ]]; then rm -rf $dest_dir/gff; fi
mkdir -p $dest_dir/gff
if [[ -d $dest_dir/bbduk ]]; then rm -rf $dest_dir/bbduk; fi
mkdir -p $dest_dir/bbduk

# create reference file
echo "source,destination" > $source_dir/reference_list.csv

############################################################################
## GFF
############################################################################
# Get a list of all gff files sorted
cd $source_dir/gff
files=($(ls *gff | sort))

# Loop through the files and rename them sequentially
counter=1
for file in "${files[@]}"; do
    # rename the sames with a reference
    cp "$file" "$dest_dir/gff/ODHL_ref${counter}.gff"
    
    # save reference info
    echo "$file,ODHL_ref${counter}" >> $source_dir/reference_list.csv

    # Increment counter
    ((counter++))
done

############################################################################
## FASTQ
############################################################################
# Get a list of all gff files sorted
cd $source_dir/bbduk
files=($(ls *gz | sort))

# Loop through the files and rename them sequentially
counter=1
for file in "${files[@]}"; do
    # rename the sames with a reference
	if [[ "$file" == *cleaned_1.fastq.gz ]]; then
        # copy file
        cp "$file" "$dest_dir/bbduk/ODHL_ref${counter}.R1.fastq.gz"

        # save reference info
        echo "$file,ODHL_ref${counter}" >> $source_dir/reference_list.csv
    elif [[ "$file" == *cleaned_2.fastq.gz ]]; then
        # copy file
        cp "$file" "$dest_dir/bbduk/ODHL_ref${counter}.R2.fastq.gz"
        
        # Increment counter after processing R2
        ((counter++))
    fi
done

############################################################################
## Complete
############################################################################
echo "Renaming complete!"; echo
cat $source_dir/reference_list.csv