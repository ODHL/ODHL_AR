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
include { arANALYZER  } from './workflows/aranalyzer'

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
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow NFCORE_ODHLAR {

    // set test samplesheet
    samplesheet = file(params.input)
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
            ch_versions
        )
            // all
            // the
            // things

        // RUN POST

            // RUN WGS

            // RUN NCBI UPLOAD
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// workflow {

//     main:
//     //
//     // SUBWORKFLOW: Run initialisation tasks
//     //
//     PIPELINE_INITIALISATION (
//         params.version,
//         params.validate_params,
//         params.monochrome_logs,
//         args,
//         params.outdir,
//         params.input
//     )

//     //
//     // WORKFLOW: Run main workflow
//     //
//     NFCORE_ODHLAR (
//         PIPELINE_INITIALISATION.out.samplesheet
//     )
//     //
//     // SUBWORKFLOW: Run completion tasks
//     //
//     PIPELINE_COMPLETION (
//         params.email,
//         params.email_on_fail,
//         params.plaintext_email,
//         params.outdir,
//         params.monochrome_logs,
//         params.hook_url,
//         NFCORE_ODHLAR.out.multiqc_report
//     )
// }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
