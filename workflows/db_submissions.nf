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


/*
========================================================================================
    CONFIG FILES
========================================================================================
*/
ch_core_functions_script    = Channel.fromPath(params.coreFunctions)
ch_wgs_db                   = Channel.fromPath(params.wgs_db)
ch_metadata_NCBI            = Channel.fromPath(params.metadata_NCBI)
ch_config_NCBI              = Channel.fromPath(params.config_NCBI)
ch_ncbi_db                  = Channel.fromPath(params.ncbi_db)
/*
========================================================================================
    IMPORT LOCAL MODULES
========================================================================================
*/

include { WGS_DB                            } from '../modules/local/wgs_db'
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
workflow dbSUBMISSION {
    take:
        ch_pipe_results
        ch_sample_list
        ch_versions

    main:
        // update the WGS database
        WGS_DB (
            ch_core_functions_script,
            ch_sample_list,
            ch_wgs_db
        )
        ch_versions         = ch_versions.mix(WGS_DB.out.versions)
        ch_wgsDB_results    = WGS_DB.out.wgs_results

        // prepare for NCBI upload
        NCBI_PREP (
            ch_core_functions_script,
            params.projectID,
            ch_metadata_NCBI,
            ch_config_NCBI,
            ch_ncbi_db,
            ch_sample_list,
            ch_pipe_results,
            ch_wgsDB_results
        )
        ch_versions = ch_versions.mix(WGS_DB.out.versions)

    
    emit:
        pipelineResults        = ch_wgsDB_results
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
