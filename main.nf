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
include { arANALYZER        } from './workflows/aranalyzer'
include { arFORMATTER       } from './workflows/arformatter'
include { arREPORTER        } from './workflows/arreporter'
include { outbreakANALYZER  } from './workflows/outbreakanalyzer'

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
//WORKFLOW: Runs basespace download, per sample
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
// WORKFLOW: Runs arAnalysis workflow, per sample
//
workflow arANALYSIS {

    // set test samplesheet
    samplesheet                 = file(params.input)
    ch_versions                 = Channel.empty()
    project_id                  = params.projectID
    
    main:
        // Set param flags
        runBASESPACE    = params.runBASESPACE.toBoolean()

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
            ch_versions
        )

    // arANALYZER.out.line_summary.view()
    // arANALYZER.out.fastp_total_qc.view()
    // arANALYZER.out.pipeStats.view()
    // arANALYZER.out.geneFiles.view()
    // arANALYZER.out.versions.view()

    
    emit:
        ch_line_summary     = arANALYZER.out.line_summary // arFORMAT
        ch_fastp_total_qc   = arANALYZER.out.fastp_total_qc // arFORMAT
        ch_pipeStats        = arANALYZER.out.pipeStats //arFORMAT
        ch_all_geneFiles    = arANALYZER.out.geneFiles // arREPORT
        ch_versions         = arANALYZER.out.versions
}

//
// WORKFLOW: Runs arFORMATTER workflow, per project
//
workflow arFORMAT {
    ch_versions                 = Channel.empty()

    main:
        // Define analysis_outdir
        def analysis_outdir = file(params.analysis_outdir)
        if (!analysis_outdir.exists()) {
            exit 1, "Error: Provided analysis_outdir '${params.analysis_outdir}' does not exist!"
        }

        // Post Analysis
        arFORMATTER(
            analysis_outdir,
            ch_versions
        )
}

//
// WORKFLOW: Runs arREPORT workflow, per project
//
workflow arREPORT {
    ch_versions                 = Channel.empty()

    main:
        // Define format_outdir
        def format_outdir = file(params.format_outdir)
        if (!format_outdir.exists()) {
            exit 1, "Error: Provided format_outdir '${params.format_outdir}' does not exist!"
        }

        // Define analysis_outdir
        def analysis_outdir = file(params.analysis_outdir)
        if (!analysis_outdir.exists()) {
            exit 1, "Error: Provided analysis_outdir '${params.analysis_outdir}' does not exist!"
        }

        // Post Analysis
        arREPORTER(
            format_outdir,
            analysis_outdir,
            ch_versions
        )
}

//
// WORKFLOW: Runs outbreakANALYSIS workflow, per project
//
workflow outbreakANALYSIS {
    // set test samplesheet
    samplesheet                 = file(params.input_gff)
    ch_versions                 = Channel.empty()

    main:
        // Define analysis_outdir
        def analysis_outdir = file(params.analysis_outdir)
        if (!analysis_outdir.exists()) {
            exit 1, "Error: Provided analysis_outdir '${params.analysis_outdir}' does not exist!"
        }

        // Define report_outdir
        def report_outdir = file(params.report_outdir)
        if (!report_outdir.exists()) {
            exit 1, "Error: Provided report_outdir '${params.report_outdir}' does not exist!"
        }

        // Define reference dir
        def reference_outdir = file(params.reference_outdir)
        if (!reference_outdir.exists()) {
            exit 1, "Error: Provided reference_outdir '${params.reference_outdir}' does not exist!"
        }

        // Post Analysis
        outbreakANALYZER(
            analysis_outdir,
            reference_outdir,
            report_outdir,
            ch_versions,
            samplesheet
        )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
