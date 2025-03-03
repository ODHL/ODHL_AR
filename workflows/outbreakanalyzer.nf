/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/


/*
========================================================================================
    SETUP
========================================================================================
*/

// Info required for completion email and summary


/*
========================================================================================
    CONFIG FILES
========================================================================================
*/
projectID                   = params.projectID
outbreak_species            = params.outbreak_species
max_samples                 = params.max_samples
percent_id                  = params.percent_id

ch_ardb                     = Channel.fromPath(params.ardb)
ch_snp_config               = Channel.fromPath(params.snp_config)
ch_outbreak_RMD             = Channel.fromPath(params.outbreak_RMD)
ch_config_arReport          = Channel.fromPath(params.config_arReport)
ch_outbreak_metadata        = Channel.fromPath(params.outbreak_metadata)
/*
========================================================================================
    IMPORT LOCAL MODULES
========================================================================================
*/
include { CFSAN                             } from '../modules/local/cfsan'
include { ROARY                             } from '../modules/local/roary'
include { IQTREE2                           } from '../modules/local/iqtree2'
include { REPORT_OUTBREAK_PREP              } from '../modules/local/report_outbreak_prep'
include { REPORT_OUTBREAK                   } from '../modules/local/report_outbreak'
/*
========================================================================================
    IMPORT LOCAL SUBWORKFLOWS
========================================================================================
*/
include { CREATE_GFF_CHANNEL                } from '../subworkflows/local/create_gff_channel'

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// MODULE: Installed directly from nf-core/modules
//


/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/
workflow outbreakANALYZER {
    take:
        // format_outdir
        analysis_outdir
        reference_outdir
        report_outdir
        ch_versions
        samplesheet

    main:
        // input check the gff manifest - ch_gff_samples
        CREATE_GFF_CHANNEL(
            samplesheet
        )
        // Extract sample IDs as key-value pairs for joining
        ch_sampleList = CREATE_GFF_CHANNEL.out.sampleList.map { it.id }

        //////////////////////////////////////////////////////////////////
        // Handle GFF files
        //////////////////////////////////////////////////////////////////
        // Join GFF files with the sample list based on matching sample_id
        ch_sample_gffs = Channel
            .fromPath("${analysis_outdir}/prokka/*gff")
            .map { file -> 
                def sample_id = file.baseName // Extracts filename without extension
                return [sample_id, file] // Key-value pair (sample_id, file)
            }
            .join(ch_sampleList)
            .map { sample_id, file -> file } // Keep only the file paths
            // .collect()
        // ch_sample_gffs.view()

        // Pull all reference files
        all_reference_gff = Channel
            .fromPath("${reference_outdir}/${outbreak_species}/gff/*gff")
            .map { file -> file } // Keep only the file paths
            // .collect()
        // all_reference_gff.view()

        // Collect and take only the first `max_samples` items
        ch_all_gffs = ch_sample_gffs.concat(all_reference_gff)
            .collect().map { collectedFiles -> 
            return collectedFiles.take(max_samples) // Keep only 1:max_samples
        }
        // ch_all_gffs.view()

        // run ROARY
        ROARY (
            ch_all_gffs,
            percent_id
        )
        ch_ROARY_aln                = ROARY.out.aln
        ch_ROARY_coreGenomeStats    = ROARY.out.core_genome_stats
        
        // Generate core genome tree
        IQTREE2 (
            ch_ROARY_aln
        )
        ch_IQTREE_genomeTree        = IQTREE2.out.genome_tree


        //////////////////////////////////////////////////////////////////
        // Handle FASTQ files
        //////////////////////////////////////////////////////////////////
        // Join fastq files with the sample list based on matching sample_id
        ch_sample_fastqs = Channel
            .fromPath("${analysis_outdir}/bbduk/*fastq.gz")
            .map { file -> 
                def sample_id = file.baseName.replaceAll(/_cleaned_[12]\.fastq$/, '') // Extracts core sample ID
                return [sample_id, file] // Key-value pair (sample_id, file)
            }
            .groupTuple() // Groups files by sample_id
            .join(ch_sampleList)
            .map { sample_id, file -> file } // Keep only the file paths
        // ch_sample_fastqs.view()

        // Pull all reference files
        all_reference_fastqs = Channel
            .fromPath("${reference_outdir}/${outbreak_species}/bbduk/*fastq.gz")
            .map { file -> file } // Keep only the file paths
        // all_reference_fastqs.view()

        // Collect and take only the first `max_samples` items
        ch_all_fastqs = ch_sample_fastqs.concat(all_reference_fastqs)
            .collect().map { collectedFiles -> 
            return collectedFiles.take(max_samples*2) // Keep only 1:max_samples
        }
        // ch_all_fastqs.view()

        // run CFSAN
        CFSAN (
            ch_all_fastqs,
            ch_ardb,
            ch_snp_config
        )
        ch_CFSAN_snpMatrix = CFSAN.out.distmatrix

        //////////////////////////////////////////////////////////////////
        // Report
        //////////////////////////////////////////////////////////////////
        ch_analyzer_results = Channel
            .fromPath("${report_outdir}/report_basic_prep/*final_report.csv")
            .map (file -> file)
            .collect()

        ch_ar_predictions = Channel
            .fromPath("${report_outdir}/report_basic_prep/*ar_predictions.tsv")
            .map (file -> file)
            .collect()

        // run outbreakPREP
        REPORT_OUTBREAK_PREP(
            ch_config_arReport,
            ch_analyzer_results,
            ch_CFSAN_snpMatrix,
            ch_IQTREE_genomeTree,
            ch_ROARY_coreGenomeStats,
            ch_ar_predictions,
            ch_outbreak_metadata,
            projectID,
            ch_outbreak_RMD
        )
        ch_updated_outbreakRMD = REPORT_OUTBREAK_PREP.out.projecOutbreakRMD

        // run outbreakREPORT
        REPORT_OUTBREAK(
            ch_config_arReport,
            ch_analyzer_results,
            ch_CFSAN_snpMatrix,
            ch_IQTREE_genomeTree,
            ch_ROARY_coreGenomeStats,
            ch_ar_predictions,
            ch_outbreak_metadata,
            projectID,
            ch_updated_outbreakRMD
        )
        ch_output=REPORT_OUTBREAK.out.report
}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

/*
========================================================================================
    THE END
========================================================================================
*/
