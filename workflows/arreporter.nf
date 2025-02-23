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
ch_id_db                    = Channel.fromPath(params.id_db)
ch_output_NCBI              = Channel.fromPath(params.output_NCBI)
ch_basic_RMD                = Channel.fromPath(params.basic_RMD)
ch_odhl_logo                = Channel.fromPath(params.odhl_logo)
ch_config_arReport          = Channel.fromPath(params.config_arReport)
/*
========================================================================================
    IMPORT LOCAL MODULES
========================================================================================
*/

include { NCBI_POST                         } from '../modules/local/ncbi_post'
include { REPORT_BASIC_PREP                 } from '../modules/local/report_basic_prep'
include { REPORT_BASIC                      } from '../modules/local/report_basic'
/*
========================================================================================
    IMPORT LOCAL SUBWORKFLOWS
========================================================================================
*/

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
workflow arREPORTER {
    take:
        format_outdir
        analysis_outdir
        ch_versions
        

    main:
        // Create channel from NCBI IDprep
        ch_ncbi_pre_file = Channel
            .fromPath("${format_outdir}/ncbi_prep/id_db_results_preNCBI.csv")
            .map (file -> file)
            .collect()

        NCBI_POST(
            projectID,
            ch_id_db,
            ch_ncbi_pre_file,
            ch_output_NCBI
        )
        ch_ncbi_post_file    = NCBI_POST.out.ncbi_post_file

        // Create channel from arProcessReport, geneFIles
        ar_summary_file = Channel
            .fromPath("${format_outdir}/post_process/processed_pipeline_results.csv")
            .map (file -> file)
            .collect()
        ch_gene_files = Channel
            .fromPath("${analysis_outdir}/amrfinderplus_run/*all_genes.tsv")
            .map (file -> file)
            .collect()

        REPORT_BASIC_PREP(
            ch_gene_files,
            ch_ncbi_post_file,
            ar_summary_file,
            ch_basic_RMD,
            projectID,
            ch_config_arReport
        )
        ch_finalReport          = REPORT_BASIC_PREP.out.finalReport
        ch_predictions          = REPORT_BASIC_PREP.out.predictions
        ch_projectBasicRMD      = REPORT_BASIC_PREP.out.projectBasicRMD

        REPORT_BASIC(
            ch_projectBasicRMD,
            projectID,
            ch_finalReport,
            ch_predictions,
            ch_config_arReport,
            ch_odhl_logo
        )
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
