#!/usr/bin/env python3

import sys
import glob
import os
import os.path
import re
from decimal import *
getcontext().prec = 4
import argparse

##Makes a summary Excel file when given a run folder from PhoeNiX
##Usage: >python Phoenix_Summary_Line_06-10-22.py -n Sequence_Name -t Trimmed_QC_Data_File -x Taxa_file -r Ratio_File -m MLST_File -u mutation_file -q Quast_File -a AR_GAMMA_File -v Hypervirulence_GAMMA_File -k trimd_kraken -s synopsis_file -o Out_File
## Written by Rich Stanton (njr5@cdc.gov) and Jill Hagey (qpk9@cdc.gov)

# Function to get the script version
def get_version():
    return "2.0.0"

def parseArgs(args=None):
    parser = argparse.ArgumentParser(description='Script to generate a PhoeNix summary line')
    parser.add_argument('-n', '--name', required=True, help='sequence name')
    parser.add_argument('-t', '--trimmed', required=False, help='QC data file for trimmed reads')
    parser.add_argument('-x', '--taxa', dest="taxa", required=False, help='Taxa file')
    parser.add_argument('-r', '--ratio', required=False, help='assembly ratio file')
    parser.add_argument('-m', '--mlst', required=False, help='MLST file')
    parser.add_argument('-u', '--mutation', dest="mutations", required=False, help='Mutation file from AMRFinder')
    parser.add_argument('-q', '--quast', required=False, help='QUAST file')
    parser.add_argument('-a', '--ar', required=False, help='AR GAMMA file')
    parser.add_argument('-p', '--pf', required=False, help='PF GAMMA file')
    parser.add_argument('-v', '--vir', required=False, help='hypervirulence GAMMA file')
    parser.add_argument('-f', '--fastani', dest="fastani", required=False, help='Fastani file or empty placeholder.')
    parser.add_argument('-k', '--kraken_trim', dest="trimd_kraken", required=False, help='trimd_summary.txt from kraken2')
    parser.add_argument('-s', '--stats', dest="stats", required=False, help='Pipeline Stats file synopsis file')
    parser.add_argument('-e', '--extended_qc', dest="extended_qc", default=False, action='store_true', help='Pass to make true for -entry cdc pipelines') # Need this for when you call -entry CDC_PHOENIX or CDC_SCAFFOLDS, but spades fails
    parser.add_argument('-o', '--out', required=True, help='output file name')
    parser.add_argument('--version', action='version', version=get_version())# Add an argument to display the version
    return parser.parse_args()

#set colors for warnings so they are seen
CRED = '\033[91m'
CEND = '\033[0m'

def MLST_Scheme(MLST_file):
    """Pulls MLST info from *_Scheme.mlst file"""
    Scheme_list = [[],[],[],[],[]]
    with open(MLST_file, 'r') as f:
        lines = f.readlines()
        lines.pop(0)
        for rawline in lines:
            line=rawline.strip()
            split_line = line.split("\t")
            source = split_line[1]
            date = split_line[2]
            DB_ID = split_line[3]
            Scheme = str(split_line[4])
            alleles = "-".join(split_line[5:])
            if DB_ID in Scheme_list[0]:
                print("In Scheme_list[0]")
                print(Scheme_list[0])
                for i in range(0,len(Scheme_list[0])):
                    if DB_ID == Scheme_list[0][i]:
                        print("Adding to", Scheme_list[0][i], i)
                        if Scheme != "-" and "Novel" not in Scheme: #if Scheme != "-" and Scheme != "Novel_allele" and Scheme != "Novel_profile":
                            Scheme_list[1][i].append("ST"+str(Scheme))
                        else:
                            Scheme_list[1][i].append(Scheme)
                        Scheme_list[2][i].append(alleles)
                        Scheme_list[3][i].append(source)
                        Scheme_list[4][i].append(date)
                        print(Scheme_list)
            else:
                print("NOT in Scheme_list[0]")
                print(Scheme_list[0], Scheme_list[1], Scheme_list[2], Scheme_list[3], Scheme_list[4])
                Scheme_list[0].append(DB_ID)
                if Scheme != "-" and Scheme != "Novel_allele" and Scheme != "Novel_profile":
                    Scheme_list[1].append(["ST"+Scheme])
                else:
                    Scheme_list[1].append([Scheme])
                Scheme_list[2].append([alleles])
                Scheme_list[3].append([source])
                Scheme_list[4].append([date])
                print(Scheme_list[0], Scheme_list[1], Scheme_list[2], Scheme_list[3], Scheme_list[4])
            for i in Scheme_list:
                for j in i:
                    print(j)
    return Scheme_list

def Contig_Count(input_quast):
    Contigs = '0'
    f = open(input_quast, 'r')
    String1 = f.readline()
    while String1 != '':
        if ('# contigs (>= 0 bp)' in String1):
            Contigs = String1.split()[-1]
            break
        String1 = f.readline()
    return Contigs

def Genome_Size(input_quast):
    Size = '0'
    f = open(input_quast, 'r')
    String1 = f.readline()
    while String1 != '':
        if ('Total length (>= 0 bp)' in String1):
            Size = String1.split()[-1]
            break
        String1 = f.readline()
    return Size

def N50_Length(input_quast):
    N50 = '0'
    f = open(input_quast, 'r')
    String1 = f.readline()
    while String1 != '':
        if ('N50' in String1):
            N50 = String1.split()[-1]
            break
        String1 = f.readline()
    return N50

def GC_Content(input_quast):
    NGC = '0'
    f = open(input_quast, 'r')
    String1 = f.readline()
    while String1 != '':
        if ('GC' in String1):
            GC = String1.split()[-1]
            break
        String1 = f.readline()
    return GC

def Assembly_Ratio(ratio_file):
    f = open(ratio_file, 'r')
    String1 = f.readline()
    Ratio = 'UNK'
    SD = 'UNK'
    while String1 != '':
        if ('Isolate_St.Devs' in String1):
            SD = String1.split()[1]
        elif ('Ratio' in String1):
            Ratio = String1.split()[1]
        String1 = f.readline()
    f.close()
    Out = Ratio + ' (' + SD + ')'
    return Out

def Assembly_Ratio_Length(ratio_file):
    f = open(ratio_file, 'r')
    String1 = f.readline()
    Length = 0
    while String1 != '':
        if ('Actual_length' in String1):
            Length = String1.split()[1]
        String1 = f.readline()
    f.close()
    Out = int(Length)
    return Out

def Trimmed_BP(trimmed_counts_file):
    # Open the file in read mode
    with open(trimmed_counts_file, 'r') as f:
        # Read the second line of data
        data_line = f.read().strip()  # Make sure to use `strip()` to remove extra whitespace
        columns = data_line.split()
    # Split the line by spaces or tabs (depending on your file format) and extract the third-to-last element
    bp = columns[-3] # The third-to-last column is assumed to be Total_Sequenced_[bp]
    # Convert the extracted BP value to an integer
    bp = int(bp)
    return bp


def Trim_Coverage(trimmed_counts_file, ratio_file):
    Length = Assembly_Ratio_Length(ratio_file)
    Trimmed = Trimmed_BP(trimmed_counts_file)
    Coverage = str(Decimal(Trimmed) / Decimal(Length))
    return Coverage

def Bla_Genes(input_gamma):
    with open(input_gamma, 'r') as f:
        next(f) # just use to skip first line
        Bla = []
        for line in f:
            Cat = line.split('\t')[0].split('__')[4] # Drug category
            Gene = line.split('\t')[0].split('__')[2] # Gene Name
            Percent_Length = float(line.split('\t')[11])*100
            Codon_Percent = float(line.split('\t')[9])*100
            if ('LACTAM' in Cat.upper()):
                # Minimum 90% length required to be included in report, otherwise not reported
                if int(round(Percent_Length)) >= 90:
                    # Minimum 98% identity required to be included in report, otherwise not reported
                    if int(round(Codon_Percent)) >= 98:
                        Bla.append(Gene)
    Bla.sort()
    return Bla

def Non_Bla_Genes(input_gamma):
    with open(input_gamma, 'r') as f:
        next(f) # just use to skip first line
        Non_Bla = []
        for line in f:
            Cat = line.split('\t')[0].split('__')[4] # Drug category
            Gene = line.split('\t')[0].split('__')[2] # Gene Name
            Percent_Length = float(line.split('\t')[11])*100
            Codon_Percent = float(line.split('\t')[9])*100
            if ('LACTAM' in Cat.upper()) == False:
                # Minimum 90% length required to be included in report, otherwise not reported
                if int(round(Percent_Length)) >= 90:
                    # Minimum 98% identity required to be included in report, otherwise not reported
                    if int(round(Codon_Percent)) >= 98:
                        Non_Bla.append(Gene)
    Non_Bla.sort()
    return Non_Bla

def HV_Genes(input_gamma):
    with open(input_gamma, 'r') as f:
        next(f) # just use to skip first line
        HV = []
        for line in f:
            Gene = line.split('\t')[0]
            HV.append(Gene)
    HV.sort()
    num_lines = sum(1 for line in open(input_gamma))
    if num_lines==1:
        HV=""
    return HV

def WT_kraken_stats(stats):
    with open(stats, 'r') as f:
        for line in f:
            if line.startswith("KRAKEN2_CLASSIFY_WEIGHTED"):
                scaffold_match = re.findall(r': .*? with', line)[0]
                scaffold_match = re.sub( ": SUCCESS  : | with", '', scaffold_match)
    return scaffold_match

def QC_Pass(stats):
    status = []
    reason = []
    warning_count = 0
    with open(stats, 'r') as f:
        for line in f:
            if ": WARNING  :" in line:
                warning_count = warning_count + 1
            if line.startswith("Auto Pass/FAIL"):
                line_status = line.split(":")[1]
                line_reason = line.split(":")[2]
                status.append(line_status.strip())
                reason.append(line_reason.strip())
                status_end = str(status[0])
                if status_end == "PASS":
                    reason_end = ""
                else:
                    reason_end = str(reason[0])
    warning_count = str(warning_count)
    return status_end, reason_end, warning_count

def Get_Kraken_reads(stats, trimd_kraken):
    with open(trimd_kraken, "r") as f:
        for line in f:
            if line.startswith("G:"):
                genus_match = line.split(": ")[1]
                genus_percent = line.split(": ")[1]
                genus_match = re.sub( "\d+|\n|\s|\.", '', genus_match)
                genus_percent = re.sub( "[a-zA-Z]*|\n|\s", '', genus_percent)
            if line.startswith("s:"):
                species_match = line.split(": ")[1]
                species_percent = line.split(": ")[1]
                species_match = re.sub( "\d+|\n|\.", '', species_match)
                species_percent = re.sub( "[a-zA-Z]*|\n|\s", '', species_percent)
        read_match = genus_match + "(" + genus_percent + "%)" + species_match + "(" + species_percent + "%)"
    return read_match

def Get_Taxa_Source(taxa_file, fastani):
    with open(taxa_file, 'r') as f:
        first_line = f.readline()
        fline=first_line.strip().split("\t")
        taxa_source=fline[0]
        percent_match=fline[1]
        # set fastani as false as default
        if (taxa_source == "ANI_REFSEQ"):
            with open(fastani, 'r' ) as f2:
                next(f2) # just use to skip first line
                for line in f2:
                    fastani_coverage = str(line.split('\t')[1])
                    percent_match = str(line.split('\t')[0]) + " ANI_match"
        if (taxa_source == "kraken2_trimmed"):
            percent_match = percent_match + "% Reads_assigned"
            fastani_coverage = "UNK1"
        if (taxa_source == "kraken2_wtasmbld"):
            percent_match = percent_match + "% Scaffolds_assigned"
            fastani_coverage = "UNK2"
        lines = f.readlines()
        for line in lines:
            if line.startswith("G:"):
                genus = line.split('\t')[1].strip('\n')
            if line.startswith("s:"):
                species = line.split('\t')[1].strip('\n')
        Species = genus + " " + species
    return taxa_source, percent_match, Species, fastani_coverage

def Get_Mutations(amr_file):
    point_mutations_list = []
    with open(amr_file, 'r') as f:
        #tsv_file = csv.reader(amr_file, delimiter="\t")
        lines = f.readlines()[1:]
        for line in lines:
            if "POINT" in line:
                point_mutations = line.split("\t")[5]
                point_mutations_list.append(point_mutations)
        if len(point_mutations_list) == 0:
            point_mutations_list = ""
        else:
            point_mutations_list = ','.join(point_mutations_list)
    return point_mutations_list

def Get_Plasmids(pf_file):
    plasmid_marker_list = []
    with open(pf_file, 'r') as f:
        next(f) # just use to skip first line
        for line in f:
            Gene = line.split('\t')[0]
            Percent_Length = float(line.split('\t')[14])*100
            Match_Percent = float(line.split('\t')[13])*100
            # Minimum 60% length required to be included in report, otherwise not reported
            if int(round(Percent_Length)) >= 60:
                # Minimum 98% identity required to be included in report, otherwise not reported
                if int(round(Match_Percent)) >= 98:
                    plasmid_marker_list.append(Gene)
    if len(plasmid_marker_list) == 0:
        plasmid_marker_list = ""
    else:
        plasmid_marker_list = ','.join(plasmid_marker_list)
    return plasmid_marker_list

def Get_BUSCO_Gene_Count(stats):
    with open(stats, 'r') as f:
        matched_line = [line for line in f if "BUSCO" in line]
        split_list = matched_line[0].split(':')
        #lineage = re.sub( "BUSCO_", '', split_list[0])
        #percent = split_list[2].split(' ')[1]
        #ratio = split_list[2].split(' ')[9].rstrip('\n')
        lineage="_".join(split_list[0].split("_")[-2:]).strip()
        percent=str(split_list[2].split("%")[0].strip())+"%"
        percent = re.sub("only ", "", percent)
        ratio="("+str(split_list[2].split("(")[1].strip())
        busco_line = percent + ' ' + ratio
    busco_file = True
    return busco_line, lineage, busco_file

def Isolate_Line(Taxa, fastani, ID, trimmed_counts, ratio_file, MLST_file, quast_file, gamma_ar, gamma_hv, stats, trimd_kraken, amr_file, pf_file, extended_qc):
    try:
        plasmid_marker_list = Get_Plasmids(pf_file)
    except:
        plasmid_marker_list = 'UNK'
    try:
        point_mutations_list = Get_Mutations(amr_file)
    except:
        point_mutations_list = 'UNK'
    try:
        taxa_source, percent_match, Species, fastani_coverage = Get_Taxa_Source(Taxa, fastani)
    except:
        taxa_source = 'UNK'
        percent_match = 'UNK'
        Species = 'UNK'
        fastani_coverage = "UNK3"
    try:
        Coverage = Trim_Coverage(trimmed_counts, ratio_file)
    except:
        Coverage = 'UNKWTFx2'
    try:
        Genome_Length = Genome_Size(quast_file)
    except:
        Genome_Length = 'UNK'
    try:
        Ratio = Assembly_Ratio(ratio_file)
    except:
        Ratio = 'UNK'
    try:
        Contigs = Contig_Count(quast_file)
    except:
        Contigs = 'UNK'
    try:
        busco_line, lineage, busco_file = Get_BUSCO_Gene_Count(stats)
    except:
        busco_file = None
        busco_line = 'UNK'
        lineage = 'UNK'
    try:
        GC = GC_Content(quast_file)
    except:
        GC = 'UNK'
    try:
        Scheme = MLST_Scheme(MLST_file)
        if len(Scheme[0]) > 1:
            if Scheme[0][0].lower() < Scheme[0][1].lower():
                MLST_scheme_1 = Scheme[0][0]
                #print("1,1-before sort", Scheme[1][0])
                mlst_types_1=sorted(Scheme[1][0])[::-1]
                MLST_type_1 = ",".join(mlst_types_1)
                if Scheme[3][0] == "srst2":
                    MLST_type_1 += '^'
                #print("1,1-after sort", MLST_type_1)
                #MLST_alleles_1 = ",".join(Scheme[2][0])
                MLST_scheme_2 = Scheme[0][1]
                #print("2,1-before sort", Scheme[1][1])
                mlst_types_2=sorted(Scheme[1][1])[::-1]
                MLST_type_2 = ",".join(mlst_types_2)
                if Scheme[3][1] == "srst2":
                    MLST_type_2 += '^'
                #print("2,1-after sort", MLST_type_2)
                #MLST_alleles_2 = ",".join(Scheme[2][1])
            else:
                MLST_scheme_1 = Scheme[0][1]
                #print("1,2-before sort", Scheme[1][1])
                mlst_types_1=sorted(Scheme[1][1])[::-1]
                MLST_type_1 = ",".join(mlst_types_1)
                if Scheme[3][1] == "srst2":
                    MLST_type_1 += '^'
                #print("1,2-after sort", MLST_type_1)
                #MLST_alleles_1 = ",".join(Scheme[2][1])
                MLST_scheme_2 = Scheme[0][0]
                #print("2,2-before sort", Scheme[1][0])
                mlst_types_2=sorted(Scheme[1][0])[::-1]
                MLST_type_2 = ",".join(mlst_types_2)
                if Scheme[3][0] == "srst2":
                    MLST_type_2 += '^'
                #print("2,2-after sort", MLST_type_2)
                #MLST_alleles_2 = ",".join(Scheme[2][0])
        else:
            MLST_scheme_1 = Scheme[0][0]
            MLST_type_1 = ",".join(Scheme[1][0])
            #MLST_alleles_1 = ",".join(Scheme[2][0])
            MLST_scheme_2 = "-"
            MLST_type_2 = "-"
            #MLST_alleles_2 = "-"
    except:
        MLST_scheme_1 = 'UNK'
        MLST_scheme_2 = 'UNK'
        MLST_type_1 = 'UNK'
        MLST_type_2 = 'UNK'
    try:
        Bla = Bla_Genes(gamma_ar)
        Bla = ','.join(Bla)
    except:
        Bla = 'UNK'
    try:
        Non_Bla = Non_Bla_Genes(gamma_ar)
        Non_Bla = ','.join(Non_Bla)
    except:
        Non_Bla = 'UNK'
    try:
        HV = HV_Genes(gamma_hv)
        if HV=="":
            pass
        else:
            HV = ','.join(HV)
    except:
        HV = 'UNK'
    try:
        scaffold_match = WT_kraken_stats(stats)
    except:
        scaffold_match = "UNK"
    try:
        QC_Outcome, Reason, warning_count = QC_Pass(stats)
    except:
        QC_Outcome = 'UNK'
        warning_count = 'UNK'
        Reason = ""
    try:
        read_match = Get_Kraken_reads(stats, trimd_kraken)
    except:
        read_match = "UNK"
    if busco_file is None and extended_qc == False:
        Line = ID + '\t' + QC_Outcome + '\t' + warning_count + '\t'  + Coverage + '\t' + Genome_Length + '\t' + Ratio + '\t' + Contigs + '\t' + GC + '\t' + Species + '\t' + percent_match + '\t' + fastani_coverage + '\t' + taxa_source + '\t' + read_match + '\t' + scaffold_match + '\t' + MLST_scheme_1 + '\t' + MLST_type_1 + '\t' + MLST_scheme_2 + '\t' + MLST_type_2 + '\t' + Bla + '\t' + Non_Bla + '\t' + point_mutations_list + '\t' + HV + '\t' + plasmid_marker_list + '\t' + Reason
        busco = False
    elif busco_file is not None or extended_qc == True:
        Line = ID + '\t' + QC_Outcome + '\t' + warning_count + '\t'  + Coverage + '\t' + Genome_Length + '\t' + Ratio + '\t' + Contigs + '\t' + GC + '\t' + busco_line + '\t' + lineage + '\t' + Species + '\t' + percent_match + '\t' + fastani_coverage + '\t' + taxa_source + '\t' + read_match + '\t' + scaffold_match + '\t' + MLST_scheme_1 + '\t' + MLST_type_1 + '\t' + MLST_scheme_2 + '\t' + MLST_type_2 + '\t' + Bla + '\t' + Non_Bla + '\t' + point_mutations_list + '\t' + HV + '\t' + plasmid_marker_list + '\t' + Reason
        busco = True
    return Line, busco, fastani

def Isolate_Line_File(Taxa, fastani, ID, trimmed_counts, ratio_file, MLST_file, quast_file, gamma_ar, gamma_hv, out_file, stats, trimd_kraken, mutations, pf_file, extended_qc):
    with open(out_file, 'w') as f:
        Line, busco, fastani = Isolate_Line(Taxa, fastani, ID, trimmed_counts, ratio_file, MLST_file, quast_file, gamma_ar, gamma_hv, stats, trimd_kraken, mutations, pf_file, extended_qc)
        if busco == True:
            f.write('ID\tAuto_QC_Outcome\tWarning_Count\tEstimated_Coverage\tGenome_Length\tAssembly_Ratio_(STDev)\t#_of_Scaffolds_>500bp\tGC_%\tBUSCO\tBUSCO_DB\tSpecies\tTaxa_Confidence\tTaxa_Coverage\tTaxa_Source\tKraken2_Trimd\tKraken2_Weighted\tMLST_Scheme_1\tMLST_1\tMLST_Scheme_2\tMLST_2\tGAMMA_Beta_Lactam_Resistance_Genes\tGAMMA_Other_AR_Genes\tAMRFinder_Point_Mutations\tHypervirulence_Genes\tPlasmid_Incompatibility_Replicons\tAuto_QC_Failure_Reason\n')
        else:
            f.write('ID\tAuto_QC_Outcome\tWarning_Count\tEstimated_Coverage\tGenome_Length\tAssembly_Ratio_(STDev)\t#_of_Scaffolds_>500bp\tGC_%\tSpecies\tTaxa_Confidence\tTaxa_Coverage\tTaxa_Source\tKraken2_Trimd\tKraken2_Weighted\tMLST_Scheme_1\tMLST_1\tMLST_Scheme_2\tMLST_2\tGAMMA_Beta_Lactam_Resistance_Genes\tGAMMA_Other_AR_Genes\tAMRFinder_Point_Mutations\tHypervirulence_Genes\tPlasmid_Incompatibility_Replicons\tAuto_QC_Failure_Reason\n')
        f.write(Line)

def main():
    args = parseArgs()
    # if the output file already exists remove it
    Isolate_Line_File(args.taxa, args.fastani, args.name, args.trimmed, args.ratio, args.mlst, args.quast, args.ar, args.vir, args.out, args.stats, args.trimd_kraken, args.mutations, args.pf, args.extended_qc)

if __name__ == '__main__':
    main()
