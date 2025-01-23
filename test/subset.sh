#!/bin/bash

# take the downloaded basespace files
output_dir="../../../output/test/basespace"

# create a temp location
if [ -d fastq ]; then rm fastq; fi
mkdir -p fastq
cp $output_dir/* fastq/
cd fastq/

# Get a list of all _R1_ and _R2_ fastq.gz files sorted
files=($(ls *_R[12]_001.fastq.gz | sort))

# Initialize a counter
counter=1

# Loop through the files and rename them sequentially
for file in "${files[@]}"; do
	echo $file

	# subset 20% of the files
	total_lines=$(zcat $file | wc -l)
	lines_to_keep=$((total_lines / 10))  # Keep 10% of the total lines
	zcat $file | awk -v lines="$lines_to_keep" 'NR <= lines' | gzip > subset_$file

	if [[ "$file" == *_R1_001.fastq.gz ]]; then
        	mv "subset_$file" "ODHL_sample${counter}.R1.fastq.gz"
    	elif [[ "$file" == *_R2_001.fastq.gz ]]; then
        	mv "subset_$file" "ODHL_sample${counter}.R2.fastq.gz"
        	((counter++)) # Increment counter after processing R2
    	fi
done

rm -rf ../*gz
echo "Renaming complete!"