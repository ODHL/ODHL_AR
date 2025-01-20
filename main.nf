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
    labResults  = file(params.labResults)
    ch_versions = Channel.empty()

    main:
        // set download variable
        needsDownload="TRUE"

        // read input
        CREATE_INPUT_CHANNEL(
            samplesheet,
            needsDownload
        )
        ch_manifest=CREATE_INPUT_CHANNEL.out.reads

        // Download test data
        //todo needsDownload
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
        // set download variable
        needsDownload="TRUE"

        // read input
        CREATE_INPUT_CHANNEL(
            samplesheet,
            needsDownload
        )
        ch_manifest=CREATE_INPUT_CHANNEL.out.reads

        // Download test data
        //todo needsDownload
        BASESPACE(ch_manifest)
        ch_reads = BASESPACE.out.reads
        
        // cleanup project name from the sampleID
        // ch_cleaned = ch_reads.map { tuple -> 
        //         def newId = tuple[0].id.split('-')[0]
        //         [[id: newId], [tuple[1]]]
        // }
        // ch_cleaned.view()

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
workflow NFCORE_ODHLAR {

    // set test samplesheet
    samplesheet = file(params.input)
    labResults  = file(params.labResults)
    ch_versions = Channel.empty()

    main:
        // TODO rewrite so this takes the WF BASESPACE and hten arANALYSIS to 
        // avoid redundant code
        // set download variable
        needsDownload="TRUE"

        // read input
        CREATE_INPUT_CHANNEL(
            samplesheet,
            needsDownload
        )
        ch_manifest=CREATE_INPUT_CHANNEL.out.reads

        // Download test data
        //todo needsDownload
        BASESPACE(ch_manifest)
        ch_reads = BASESPACE.out.reads
        
        // cleanup project name from the sampleID
        // ch_cleaned = ch_reads.map { tuple -> 
        //         def newId = tuple[0].id.split('-')[0]
        //         [[id: newId], [tuple[1]]]
        // }
        // ch_cleaned.view()

        // RUN PHOENIX
        arANALYZER(
            ch_reads,
            labResults,
            ch_versions
        )
        ch_pipe_results = arANALYZER.out.pipe_results
        ch_quality_results = arANALYZER.out.quality_results
        ch_versions = arANALYZER.out.versions

        // filter quality samples
        ch_quality_results.view()

        // Submit to WGS DB, Prepare for NCBI DB
        dbSUBMISSION(
            ch_pipe_results,
            ch_quality_results,
            ch_versions
        )

        //TODO fix this so it runs
    //     PIPELINE_COMPLETION (
    //         params.email,
    //         params.email_on_fail,
    //         params.plaintext_email,
    //         params.outdir,
    //         params.monochrome_logs,
    //         params.hook_url,
    //         NFCORE_ODHLAR.out.multiqc_report
    //     )
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
        needsDownload="TRUE"
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
        needsDownload="TRUE"
    
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
        needsDownload="TRUE"
    
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
        needsDownload="TRUE"
        // outbreakANALYSIS()

        //outbreakREPORTING
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
