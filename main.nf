#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/odhlar
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/odhlar
    Website: https://nf-co.re/odhlar
    Slack  : https://nfcore.slack.com/channels/odhlar
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Main workflows
include { arANALYZER    } from './workflows/aranalyzer'
include { dbSUBMISSION  } from './workflows/db_submissions'

// Subworkflows
include { CREATE_INPUT_CHANNEL    } from './subworkflows/local/create_input_channel'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_odhlar_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_odhlar_pipeline'

// Modules
include { BASESPACE                 } from './modules/local/basespace'
include { NCBI_POST                 } from './modules/local/ncbi_post'
include { REPORT_PREP               } from './modules/local/report_prep'
include { REPORT_BASIC              } from './modules/local/report_basic'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
//
//WORKFLOW: Only downloads samples
//
workflow arBASESPACE {

    // set test samplesheet
    samplesheet = file(params.input)
    ch_versions = Channel.empty()

    main:
        // set download variable
        runBASESPACE="TRUE"

        // read input
        CREATE_INPUT_CHANNEL(
            samplesheet,
            runBASESPACE
        )
        ch_manifest=CREATE_INPUT_CHANNEL.out.reads

        // Download test data
        BASESPACE(ch_manifest)
        ch_reads = BASESPACE.out.reads
}

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow arANALYSIS {

    // set test samplesheet
    samplesheet                 = file(params.input)
    labResults                  = file(params.labResults)
    ch_versions                 = Channel.empty()
    project_id                  = params.projectID
    ch_wgs_db                   = Channel.fromPath(params.wgs_db)
    ch_ncbi_db                  = Channel.fromPath(params.ncbi_db)
    ch_core_functions_script    = Channel.fromPath(params.coreFunctions)
    ch_basic_RMD                = Channel.fromPath(params.basic_RMD)
    ch_config_arReport          = Channel.fromPath(params.config_arReport)
    ch_odhl_logo                = Channel.fromPath(params.odhl_logo)
    
    main:
        // Set param flags
        runBASESPACE    = params.runBASESPACE.toBoolean()
        runNcbiProcess  = params.runNcbiProcess.toBoolean()
        runBasicReport  = params.runBasicReport.toBoolean()

        // Read input
        CREATE_INPUT_CHANNEL(
            samplesheet,
            runBASESPACE
        )
        ch_manifest = CREATE_INPUT_CHANNEL.out.reads

        // Conditional execution for download
        if (runBASESPACE) {
            // Download test data
            BASESPACE(ch_manifest)
            ch_reads = BASESPACE.out.reads
        } else {
            ch_reads = ch_manifest
        }

        // RUN PHOENIX
        arANALYZER(
            ch_reads,
            labResults,
            ch_versions
        )
        ch_analyzer_results = arANALYZER.out.pipe_results
        ch_quality_results  = arANALYZER.out.quality_results
        ch_all_geneFiles    = arANALYZER.out.geneFiles
        ch_versions         = arANALYZER.out.versions

        // Submit to WGS DB, Prepare for NCBI DB
        dbSUBMISSION(
            ch_analyzer_results,
            ch_quality_results,
            ch_versions
        )
        ch_pipelineResults = dbSUBMISSION.out.pipelineResults

        // POST NCBI
        if (runNcbiProcess) {
            NCBI_POST(
                project_id,
                ch_ncbi_db,
                ch_wgs_db,
                ch_quality_results
            )
            ch_ncbi_output = NCBI_POST.out.ncbi_output
        }

        // Basic Report
        if (runBasicReport){
            REPORT_PREP(
                ch_core_functions_script,
                ch_basic_RMD,
                project_id,
                ch_analyzer_results,
                ch_ncbi_db,
                ch_wgs_db,
                ch_all_geneFiles
            )
            ch_final_report        = REPORT_PREP.out.CSVreport
            ch_updated_basicRMD    = REPORT_PREP.out.RMD
            ch_predictions         = REPORT_PREP.out.predictions

            REPORT_BASIC(
                ch_updated_basicRMD,
                project_id,
                ch_final_report,
                ch_predictions,
                ch_config_arReport,
                ch_odhl_logo
            )
            ch_basicHTMLreport    = REPORT_BASIC.out.HTMLreport
            ch_basicHTMLreport.view()
        }

    emit:
        pipelineResults     = ch_pipelineResults
        quality_results     = ch_quality_results
        basicHTMLreport     = ch_basicHTMLreport
}

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow outbreakANALYSIS {

    // set test samplesheet
    samplesheet = file(params.input)
    labResults  = file(params.labResults)
    ch_versions = Channel.empty()

    main:
        // set download variable
        runBASESPACE="TRUE"
    
    //     emit:
    //         valid_samplesheet            = BUILD_TREE.out.valid_samplesheet
    //         // bams                         = BUILD_TREE.out.bams
    //         // distmatrix                   = BUILD_TREE.out.distmatrix
    //         // core_stats  = BUILD_TREE.out.core_stats
    //         // tree        = BUILD_TREE.out.tree
    //         // samestr_db  = BUILD_TREE.out.samestr_db
}

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow outbreakREPORTING {

    // set test samplesheet
    samplesheet = file(params.input)
    labResults  = file(params.labResults)
    ch_versions = Channel.empty()

    main:
        // set download variable
        runBASESPACE="TRUE"
    
    //     emit:
//         report_basic            = CREATE_REPORT.out.report_out

}

workflow NFCORE_OUTBREAK {

    // set test samplesheet
    samplesheet = file(params.input)
    labResults  = file(params.labResults)
    ch_versions = Channel.empty()

    main:
        // TODO 
        runBASESPACE="TRUE"
        // outbreakANALYSIS()

        //outbreakREPORTING
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
