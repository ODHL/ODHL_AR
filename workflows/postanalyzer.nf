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
def multiqc_report = []


/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

ch_core_functions_script    = Channel.fromPath(params.coreFunctions)
ch_id_db                    = Channel.fromPath(params.id_db)
ch_metadata_NCBI            = Channel.fromPath(params.metadata_NCBI)
ch_config_NCBI              = Channel.fromPath(params.config_NCBI)
labResults                  = file(params.labResults)


ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

/*
========================================================================================
    IMPORT LOCAL MODULES
========================================================================================
*/

include { CREATE_PHOENIX_SUMMARY            } from '../modules/local/create_phoenix_summary'
include { POST_PROCESS                      } from '../modules/local/post_process'
include { ID_DB                             } from '../modules/local/id_db'

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

include { MULTIQC                } from '../modules/nf-core/multiqc/main'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/
workflow postANALYZER {
    take:
        ch_line_summary
        ch_fastp_total_qc
        ch_pipeStats
        ch_versions

    main:
        // Combining sample summaries into final report
        all_summaries_ch    = ch_line_summary.collect()
        CREATE_PHOENIX_SUMMARY (
            all_summaries_ch, 
            params.run_busco
        )
        ch_versions = ch_versions.mix(CREATE_PHOENIX_SUMMARY.out.versions)
        final_phoenix_summary = CREATE_PHOENIX_SUMMARY.out.summary_report

        // Remap all files into one
        all_fastp_files     = ch_fastp_total_qc.map { it[1] }  // Extract just the file path
        all_pipeStats_files = ch_pipeStats.map { it[1] }  // Extract just the file path
        all_files_ch        = all_fastp_files.concat(all_pipeStats_files).collect()

        // Run post processing
        POST_PROCESS(
            all_files_ch,
            final_phoenix_summary,
            params.core_functions_script,
            labResults
        )
        ch_pipe_results = POST_PROCESS.out.pipeline_results
        ch_quality_results = POST_PROCESS.out.quality_results
        ch_versions = ch_versions.mix(POST_PROCESS.out.versions)

        // update the ID database
        ID_DB (
            ch_core_functions_script,
            ch_pipe_results,
            ch_quality_results,
            ch_id_db
        )
        ch_versions         = ch_versions.mix(WGS_DB.out.versions)
        ch_wgsDB_results    = WGS_DB.out.wgs_results

    //     // prepare for NCBI upload
    //     NCBI_PREP (
    //         ch_core_functions_script,
    //         params.projectID,
    //         ch_metadata_NCBI,
    //         ch_config_NCBI,
    //         ch_ncbi_db,
    //         ch_sample_list,
    //         ch_pipe_results,
    //         ch_wgsDB_results
    //     )
    //     ch_versions = ch_versions.mix(WGS_DB.out.versions)

    //     // Run post processing
    //     POST_PROCESS(
    //         all_files_ch,
    //         final_phoenix_summary,
    //         params.core_functions_script,
    //         ch_labResults
    //     )
    //     ch_pipe_results = POST_PROCESS.out.pipeline_results
    //     ch_quality_results = POST_PROCESS.out.quality_results
    //     ch_versions = ch_versions.mix(POST_PROCESS.out.versions)

    // emit:
    //     ch_line_summary
    //     ch_fastp_total_qc
    //     ch_pipeStats
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
