# bash files_source.sh pseudo pseudomonas 
# set args
id_in=$1
id_out=$2

# set dir
dest_dir="/home/ubuntu/workflows/ODHL_AR/assets/databases/outbreak/internal/$id_out"

############################################################################
## GFF
############################################################################
# create the gff directory
if [[ -d $dest_dir/gff ]]; then rm -rf $dest_dir/gff; fi
mkdir -p $dest_dir/gff

# copy files from source to destination
source_dir="/home/ubuntu/output/$id_in/results/ar*/prokka/"
cp $source_dir/*gff $dest_dir/gff

############################################################################
## GFF
############################################################################
# create the bbduk directory
if [[ -d $dest_dir/bbduk ]]; then rm -rf $dest_dir/bbduk; fi
mkdir -p $dest_dir/bbduk

# copy files from source to destination
source_dir="/home/ubuntu/output/$id_in/results/ar*/bbduk/"
cp $source_dir/*gz $dest_dir/bbduk

############################################################################
## GFF
############################################################################
echo "cp complete!"
ls $dest_dir/gff
ls $dest_dir/bbduk