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
    samplesheet = file(params.input)
    labResults  = file(params.labResults)
    ch_versions = Channel.empty()

    main:
        // set download 
        runBASESPACE = params.runBASESPACE.toBoolean()

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
        ch_pipe_results = arANALYZER.out.pipe_results
        ch_quality_results = arANALYZER.out.quality_results
        ch_versions = arANALYZER.out.versions

        // Submit to WGS DB, Prepare for NCBI DB
        dbSUBMISSION(
            ch_pipe_results,
            ch_quality_results,
            ch_versions
        )
}

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow DBProcessing {

    // set test samplesheet
    samplesheet = file(params.input)
    labResults  = file(params.labResults)
    ch_versions = Channel.empty()

    main:
        // set download variable
        runBASESPACE="TRUE"
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
