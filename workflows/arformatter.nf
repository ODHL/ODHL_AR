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

ch_core_functions_script    = Channel.fromPath(params.coreFunctions)
ch_labResults               = Channel.fromPath(params.labResults)
ch_id_db                    = Channel.fromPath(params.id_db)
projectID                   = params.projectID
ch_metadata_NCBI            = Channel.fromPath(params.metadata_NCBI)
ch_config_NCBI              = Channel.fromPath(params.config_NCBI)

/*
========================================================================================
    IMPORT LOCAL MODULES
========================================================================================
*/

include { CREATE_PHOENIX_SUMMARY            } from '../modules/local/create_phoenix_summary'
include { POST_PROCESS                      } from '../modules/local/post_process'
include { ID_DB                             } from '../modules/local/id_db'
include { NCBI_PREP                         } from '../modules/local/ncbi_prep'

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
workflow arFORMATTER {
    take:
        analysis_outdir
        ch_versions

    main:
        // Create channel from summary files
        all_summaries_ch = Channel
            .fromPath("${analysis_outdir}/create_phoenix_summary_line/*summaryline.tsv")
            // .map { file -> tuple(file.name, file) }  // Create tuple with filename and file path
            .map (file -> file)
            .collect()

        // Combining sample summaries into final report
        CREATE_PHOENIX_SUMMARY (
            all_summaries_ch, 
            params.runBUSCO
        )
        ch_versions = ch_versions.mix(CREATE_PHOENIX_SUMMARY.out.versions)
        final_phoenix_summary = CREATE_PHOENIX_SUMMARY.out.summary_report

        // Remap fastp and pipeStats files into one
        // ch_pipeStats.map { it[1] }
        all_fastp_files = Channel
            .fromPath("${analysis_outdir}/get_trimd_stats/*_trimmed_read_counts.txt")
            .map (file -> file)
            .collect()
        all_pipeStats_files = Channel
            .fromPath("${analysis_outdir}/generate_pipeline_stats/*.synopsis")
            .map (file -> file)
            .collect()
        all_files_ch = all_fastp_files.concat(all_pipeStats_files).collect()

        // Run post processing
        POST_PROCESS(
            all_files_ch,
            final_phoenix_summary,
            params.core_functions_script,
            ch_labResults
        )
        ch_pipe_results = POST_PROCESS.out.pipeline_results
        ch_quality_results = POST_PROCESS.out.quality_results
        ch_versions = ch_versions.mix(POST_PROCESS.out.versions)

        // update the ID database
        ID_DB (
            ch_core_functions_script,
            ch_quality_results,
            ch_id_db,
            projectID
        )
        ch_versions         = ch_versions.mix(ID_DB.out.versions)
        ch_ID_results       = ID_DB.out.wgs_results

        // prepare for NCBI upload
        //// if the samples are test they wont be stored in basespace dir
        if (!file("params.analysis_outdir/basespace").exists()) {
            all_fastq_files = Channel
                .fromPath("/home/ubuntu/workflows/ODHL_AR/test/fastq/*fastq.gz")
                .map (file -> file)
                .collect()            
        } else {
            all_fastq_files = Channel
                .fromPath("${analysis_outdir}/basespace/*fastq.gz")
                .map (file -> file)
                .collect()
        }
        NCBI_PREP (
            ch_core_functions_script,
            projectID,
            ch_metadata_NCBI,
            ch_config_NCBI,
            ch_id_db,
            ch_pipe_results,
            ch_ID_results,
            all_fastq_files
        )
        ch_versions         = ch_versions.mix(NCBI_PREP.out.versions)
        ch_ncbi_att         = NCBI_PREP.out.ncbi_att
        ch_ncbi_meta        = NCBI_PREP.out.ncbi_meta
        ch_ncbi_pre_file    = NCBI_PREP.out.ncbi_pre_file

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
