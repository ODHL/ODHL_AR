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

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

/*
========================================================================================
    IMPORT LOCAL MODULES
========================================================================================
*/

// include { ASSET_CHECK                    } from './modules/local/asset_check'
include { CORRUPTION_CHECK               } from '../modules/local/fairy_corruption_check'
include { GET_RAW_STATS                  } from '../modules/local/get_raw_stats'
include { BBDUK                          } from '../modules/local/bbduk'
include { FASTP as FASTP_TRIMD           } from '../modules/local/fastp'
include { FASTP_SINGLES                  } from '../modules/local/fastp_singles'
include { GET_TRIMD_STATS                } from '../modules/local/get_trimd_stats'
// include { FASTQC                         } from '../modules/local/fastqc'

// include { RENAME_FASTA_HEADERS           } from '../modules/local/rename_fasta_headers'
// include { GAMMA_S as GAMMA_PF            } from '../modules/local/gammas'
// include { GAMMA as GAMMA_AR              } from '../modules/local/gamma'
// include { GAMMA as GAMMA_HV              } from '../modules/local/gamma'
// include { MLST                           } from '../modules/local/mlst'
// include { BBMAP_REFORMAT                 } from '../modules/odhl/contig_less500'
// include { SCAFFOLD_COUNT_CHECK           } from '../modules/local/fairy_scaffold_count_check'
// include { QUAST                          } from '../modules/local/quast'
// include { MASH_DIST                      } from '../modules/local/mash_distance'
// include { FASTANI                        } from '../modules/local/fastani'
// include { DETERMINE_TOP_MASH_HITS        } from '../modules/local/determine_top_mash_hits'
// include { FORMAT_ANI                     } from '../modules/odhl/format_ANI_best_hit'
// include { DETERMINE_TAXA_ID              } from '../modules/local/determine_taxa_id'
// include { PROKKA                         } from '../modules/local/prokka'
// include { GET_TAXA_FOR_AMRFINDER         } from '../modules/local/get_taxa_for_amrfinder'
// include { AMRFINDERPLUS_RUN              } from '../modules/local/run_amrfinder'
// include { CALCULATE_ASSEMBLY_RATIO       } from '../modules/local/assembly_ratio'
// include { CREATE_SUMMARY_LINE            } from '../modules/local/phoenix_summary_line'
// include { FETCH_FAILED_SUMMARIES         } from '../modules/local/fetch_failed_summaries'
// include { GATHER_SUMMARY_LINES           } from '../modules/local/phoenix_summary'
// include { GRIPHIN                        } from '../modules/local/griphin'
// include { CREATE_NCBI_UPLOAD_SHEET       } from '../modules/local/create_ncbi_upload_sheet'

/*
========================================================================================
    IMPORT LOCAL SUBWORKFLOWS
========================================================================================
*/

// include { KRAKEN2_WF as KRAKEN2_TRIMD    } from '../subworkflows/odhl/kraken2krona'
// include { GENERATE_PIPELINE_STATS_WF     } from '../subworkflows/odhl/generate_pipeline_stats'
// include { SPADES_WF                      } from '../subworkflows/odhl/spades_failure'
// include { KRAKEN2_WF as KRAKEN2_ASMBLD   } from '../subworkflows/odhl/kraken2krona'
// include { KRAKEN2_WF as KRAKEN2_WTASMBLD } from '../subworkflows/odhl/kraken2krona'
// include { DO_MLST                        } from '../subworkflows/local/do_mlst'

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
workflow arANALYZER {
    take:
        ch_reads
        ch_versions

    main:
        // Allow relative paths for krakendb argument
        ch_kraken2_db  = Channel.fromPath(params.kraken2_db, relative: true)

        // unzip any zipped databases
        // ASSET_CHECK (
        //     params.zipped_sketch, params.custom_mlstdb, kraken2_db_path
        // )
        // ch_versions = ch_versions.mix(ASSET_CHECK.out.versions)

        // fairy compressed file corruption check & generate read stats
        CORRUPTION_CHECK (
            ch_reads, 
            params.run_busco
        )
        ch_versions = ch_versions.mix(CORRUPTION_CHECK.out.versions)
        ch_corruptionStatus=CORRUPTION_CHECK.out.outcome

        //Combining reads with output of corruption check. By=2 is for getting R1 and R2 results
        read_stats_ch = ch_reads
            .join(ch_corruptionStatus, by: [0,0])
            .join(ch_corruptionStatus.splitCsv(strip:true, by:2)
            .map{meta, fairy_outcome -> [meta, [fairy_outcome[0][0], fairy_outcome[1][0]]]}, by: [0,0])
            .filter { it[3].findAll {!it.contains('FAILED')}}

        // Get stats on raw reads if the reads aren't corrupted
        GET_RAW_STATS (
            read_stats_ch, params.run_busco // false says no busco is being run
        )
        ch_versions = ch_versions.mix(GET_RAW_STATS.out.versions)
        ch_rawStatus=GET_RAW_STATS.out.raw_outcome
        ch_rawStats=GET_RAW_STATS.out.combined_raw_stats

        // Combining reads with output of corruption check
        bbduk_ch = ch_reads
            .join(ch_rawStatus.splitCsv(strip:true, by:3)
            .map{meta, fairy_outcome -> [meta, [fairy_outcome[0][0]]]}, by: [0,0])
            .filter { it[1].findAll {!it.contains('FAILED')}}

        // Remove PhiX reads
        BBDUK (
            bbduk_ch, params.bbdukdb
        )
        ch_versions = ch_versions.mix(BBDUK.out.versions)

        // Trim and remove low quality reads
        FASTP_TRIMD (
            BBDUK.out.reads, params.save_trimmed_fail, params.save_merged
        )
        ch_versions = ch_versions.mix(FASTP_TRIMD.out.versions)
        ch_trimmedJson=FASTP_TRIMD.out.json

        // Rerun on unpaired reads to get stats, nothing removed
        FASTP_SINGLES (
            FASTP_TRIMD.out.reads_fail
        )
        ch_versions = ch_versions.mix(FASTP_SINGLES.out.versions)
        ch_singlesJson=FASTP_SINGLES.out.json

        // Combining fastp json outputs based on meta.id
        fastp_json_ch = FASTP_TRIMD.out.json.join(FASTP_SINGLES.out.json, by: [0,0])
        .join(ch_rawStats, by: [0,0])\
        .join(ch_corruptionStatus, by: [0,0])

        // Script gathers data from fastp jsons for pipeline stats file
        GET_TRIMD_STATS (
            fastp_json_ch, params.run_busco // false says no busco is being run
        )
        ch_versions = ch_versions.mix(GET_TRIMD_STATS.out.versions)

        // combing fastp_trimd information with fairy check of reads to confirm there are reads after filtering
        // trimd_reads_file_integrity_ch = FASTP_TRIMD.out.reads
        //     .join(GET_TRIMD_STATS.out.outcome.splitCsv(strip:true, by:5)
        //     .map{meta, fairy_outcome -> [meta, [fairy_outcome[0][0], fairy_outcome[1][0], fairy_outcome[2][0], fairy_outcome[3][0], fairy_outcome[4][0]]]}, by: [0,0])
        //     .filter { it[2].findAll {!it.contains('FAILED')}}

        // Running Fastqc on trimmed reads
        // FASTQC (
        //     trimd_reads_file_integrity_ch
        // )
        // ch_versions = ch_versions.mix(FASTQC.out.versions.first())

        // // Checking for Contamination in trimmed reads, creating krona plots and best hit files
        // KRAKEN2_TRIMD (
        //     FASTP_TRIMD.out.reads, GET_TRIMD_STATS.out.outcome, "trimd", GET_TRIMD_STATS.out.fastp_total_qc, [], ASSET_CHECK.out.kraken_db, "reads"
        // )
        // ch_versions = ch_versions.mix(KRAKEN2_TRIMD.out.versions)

        // SPADES_WF (
        //     FASTP_SINGLES.out.reads, \
        //     FASTP_TRIMD.out.reads, \
        //     GET_TRIMD_STATS.out.fastp_total_qc, \
        //     GET_RAW_STATS.out.combined_raw_stats, \
        //     [], \
        //     KRAKEN2_TRIMD.out.report, \
        //     KRAKEN2_TRIMD.out.krona_html, \
        //     KRAKEN2_TRIMD.out.k2_bh_summary, \
        //     params.extended_qc
        // )
        // ch_versions = ch_versions.mix(SPADES_WF.out.versions)

        // // Rename scaffold headers
        // RENAME_FASTA_HEADERS (
        //     SPADES_WF.out.spades_ch
        // )
        // ch_versions = ch_versions.mix(RENAME_FASTA_HEADERS.out.versions)

        // // Removing scaffolds <500bp
        // BBMAP_REFORMAT (
        //     RENAME_FASTA_HEADERS.out.renamed_scaffolds
        // )
        // ch_versions = ch_versions.mix(BBMAP_REFORMAT.out.versions)

        // // Combine bbmap log with the fairy outcome file
        // scaffold_check_ch = BBMAP_REFORMAT.out.log.map{      meta, log                -> [[id:meta.id], log]}\
        // .join(GET_TRIMD_STATS.out.outcome.map{               meta, outcome            -> [[id:meta.id], outcome]},    by: [0])\
        // .join(GET_RAW_STATS.out.combined_raw_stats.map{      meta, combined_raw_stats -> [[id:meta.id], combined_raw_stats]}, by: [0])\
        // .join(GET_TRIMD_STATS.out.fastp_total_qc.map{        meta, fastp_total_qc     -> [[id:meta.id], fastp_total_qc]},     by: [0])\
        // .join(KRAKEN2_TRIMD.out.report.map{                  meta, report             -> [[id:meta.id], report]},             by: [0])\
        // .join(KRAKEN2_TRIMD.out.k2_bh_summary.map{           meta, k2_bh_summary      -> [[id:meta.id], k2_bh_summary]},      by: [0])\
        // .join(KRAKEN2_TRIMD.out.krona_html.map{              meta, krona_html         -> [[id:meta.id], krona_html]},         by: [0])

        // // Checking that there are still scaffolds left after filtering
        // SCAFFOLD_COUNT_CHECK (
        //     scaffold_check_ch, params.extended_qc, params.coverage, params.nodes, params.names
        // )
        // ch_versions = ch_versions.mix(SCAFFOLD_COUNT_CHECK.out.versions)

        // //combing scaffolds with scaffold check information to ensure processes that need scaffolds only run when there are scaffolds in the file
        // filtered_scaffolds_ch = BBMAP_REFORMAT.out.filtered_scaffolds.map{    meta, filtered_scaffolds -> [[id:meta.id], filtered_scaffolds]}
        //     .join(SCAFFOLD_COUNT_CHECK.out.outcome.splitCsv(strip:true, by:5)
        //     .map{meta, fairy_outcome      -> [meta, [fairy_outcome[0][0], fairy_outcome[1][0], fairy_outcome[2][0], fairy_outcome[3][0], fairy_outcome[4][0]]]}, by: [0])
        //     .filter { it[2].findAll {it.contains('PASSED: More than 0 scaffolds')}}
        
        // // Running gamma to identify hypervirulence genes in scaffolds
        // GAMMA_HV (
        //     filtered_scaffolds_ch, params.hvgamdb
        // )
        // ch_versions = ch_versions.mix(GAMMA_HV.out.versions)

        // // Running gamma to identify AR genes in scaffolds
        // GAMMA_AR (
        //     filtered_scaffolds_ch, params.ardb
        // )
        // ch_versions = ch_versions.mix(GAMMA_AR.out.versions)

        // GAMMA_PF (
        //     filtered_scaffolds_ch, params.gamdbpf
        // )
        // ch_versions = ch_versions.mix(GAMMA_PF.out.versions)

        // // Getting Assembly Stats
        // QUAST (
        //     filtered_scaffolds_ch
        // )
        // ch_versions = ch_versions.mix(QUAST.out.versions)

        // // get gff and protein files for amrfinder+
        // PROKKA (
        //     filtered_scaffolds_ch, [], []
        // )
        // ch_versions = ch_versions.mix(PROKKA.out.versions)

        // // Creating krona plots and best hit files for weighted assembly
        // KRAKEN2_WTASMBLD (
        //     BBMAP_REFORMAT.out.filtered_scaffolds, SCAFFOLD_COUNT_CHECK.out.outcome, "wtasmbld", [], QUAST.out.report_tsv, ASSET_CHECK.out.kraken_db, "reads"
        // )
        // ch_versions = ch_versions.mix(KRAKEN2_WTASMBLD.out.versions)

        // // combine filtered scaffolds and mash_sketch so mash_sketch goes with each filtered_scaffolds file
        // mash_dist_ch = filtered_scaffolds_ch.combine(ASSET_CHECK.out.mash_sketch)

        // // Running Mash distance to get top 20 matches for fastANI to speed things up
        // MASH_DIST (
        //     mash_dist_ch
        // )
        // ch_versions = ch_versions.mix(MASH_DIST.out.versions)

        // // Combining mash dist with filtered scaffolds and the outcome of the scaffolds count check based on meta.id
        // top_mash_hits_ch = MASH_DIST.out.dist.join(filtered_scaffolds_ch, by: [0])

        // // Generate file with list of paths of top taxa for fastANI
        // DETERMINE_TOP_MASH_HITS (
        //     top_mash_hits_ch
        // )
        // ch_versions = ch_versions.mix(DETERMINE_TOP_MASH_HITS.out.versions)

        // // Combining filtered scaffolds with the top taxa list based on meta.id
        // top_taxa_list_ch = BBMAP_REFORMAT.out.filtered_scaffolds.map{meta, filtered_scaffolds -> [[id:meta.id], filtered_scaffolds]}\
        // .join(DETERMINE_TOP_MASH_HITS.out.top_taxa_list.map{              meta, top_taxa_list      -> [[id:meta.id], top_taxa_list ]}, by: [0])\
        // .join(DETERMINE_TOP_MASH_HITS.out.reference_dir.map{              meta, reference_dir      -> [[id:meta.id], reference_dir ]}, by: [0])

        // // Getting species ID
        // FASTANI (
        //     top_taxa_list_ch
        // )
        // ch_versions = ch_versions.mix(FASTANI.out.versions)

        // // Reformat ANI headers
        // FORMAT_ANI (
        //     FASTANI.out.ani
        // )
        // ch_versions = ch_versions.mix(FORMAT_ANI.out.versions)

        // // Combining weighted kraken report with the FastANI hit based on meta.id
        // best_hit_ch = KRAKEN2_WTASMBLD.out.k2_bh_summary.map{meta, k2_bh_summary -> [[id:meta.id], k2_bh_summary]}\
        // .join(FORMAT_ANI.out.ani_best_hit.map{               meta, ani_best_hit  -> [[id:meta.id], ani_best_hit ]},  by: [0])\
        // .join(KRAKEN2_TRIMD.out.k2_bh_summary.map{           meta, k2_bh_summary -> [[id:meta.id], k2_bh_summary ]}, by: [0])

        // // Getting ID from either FastANI or if fails, from Kraken2
        // DETERMINE_TAXA_ID (
        //     best_hit_ch, params.nodes, params.names
        // )
        // ch_versions = ch_versions.mix(DETERMINE_TAXA_ID.out.versions)

        // // Perform MLST steps on isolates (with srst2 on internal samples)
        // DO_MLST (
        //     BBMAP_REFORMAT.out.filtered_scaffolds, \
        //     SCAFFOLD_COUNT_CHECK.out.outcome, \
        //     FASTP_TRIMD.out.reads, \
        //     DETERMINE_TAXA_ID.out.taxonomy, \
        //     ASSET_CHECK.out.mlst_db, \
        //     params.run_srst2_mlst
        // )
        // ch_versions = ch_versions.mix(DO_MLST.out.versions)

        // /*// Fetch AMRFinder Database
        // AMRFINDERPLUS_UPDATE( )
        // ch_versions = ch_versions.mix(AMRFINDERPLUS_UPDATE.out.versions)*/

        // // Create file that has the organism name to pass to AMRFinder
        // GET_TAXA_FOR_AMRFINDER (
        //     DETERMINE_TAXA_ID.out.taxonomy
        // )
        // ch_versions = ch_versions.mix(GET_TAXA_FOR_AMRFINDER.out.versions)

        // // Combining taxa and scaffolds to run amrfinder and get the point mutations.
        // amr_channel = BBMAP_REFORMAT.out.filtered_scaffolds.map{                 meta, reads          -> [[id:meta.id], reads]}\
        // .join(GET_TAXA_FOR_AMRFINDER.out.amrfinder_taxa.splitCsv(strip:true).map{meta, amrfinder_taxa -> [[id:meta.id], amrfinder_taxa ]}, by: [0])\
        // .join(PROKKA.out.faa.map{                                                meta, faa            -> [[id:meta.id], faa ]},            by: [0])\
        // .join(PROKKA.out.gff.map{                                                meta, gff            -> [[id:meta.id], gff ]},            by: [0])

        // // Run AMRFinder
        // AMRFINDERPLUS_RUN (
        //     amr_channel, params.amrfinder_db
        // )
        // ch_versions = ch_versions.mix(AMRFINDERPLUS_RUN.out.versions)

        // // Combining determined taxa with the assembly stats based on meta.id
        // assembly_ratios_ch = DETERMINE_TAXA_ID.out.taxonomy.map{meta, taxonomy   -> [[id:meta.id], taxonomy]}\
        // .join(QUAST.out.report_tsv.map{                         meta, report_tsv -> [[id:meta.id], report_tsv]}, by: [0])

        // // Calculating the assembly ratio and gather GC% stats
        // CALCULATE_ASSEMBLY_RATIO (
        //     assembly_ratios_ch, params.ncbi_assembly_stats
        // )
        // ch_versions = ch_versions.mix(CALCULATE_ASSEMBLY_RATIO.out.versions)

        // // prepare inputs to the stats wf
        // if (params.run_srst2_mlst){
        //     fullgene_results=SRST2_TRIMD_AR.out.fullgene_results
        // } else {
        //     fullgene_results=[]
        // }
        // if (params.asmbld){
        //     asmbld_report=KRAKEN2_ASMBLD.out.report                 // channel: tuple (meta) path(report)
        //     asmbld_krona_html=KRAKEN2_ASMBLD.out.krona_html         // channel: tuple (meta) path(krona_html)
        //     asmbld_k2_bh_summary=KRAKEN2_ASMBLD.out.k2_bh_summary   // channel: tuple (meta) path(k2_bh_summary)
        // } else{
        //     asmbld_report=[]
        //     asmbld_krona_html=[]
        //     asmbld_k2_bh_summary=[]
        // }

        // GENERATE_PIPELINE_STATS_WF (
        //     GET_RAW_STATS.out.combined_raw_stats, \
        //     GET_TRIMD_STATS.out.fastp_total_qc, \
        //     fullgene_results, \
        //     KRAKEN2_TRIMD.out.report, \
        //     KRAKEN2_TRIMD.out.krona_html, \
        //     KRAKEN2_TRIMD.out.k2_bh_summary, \
        //     RENAME_FASTA_HEADERS.out.renamed_scaffolds, \
        //     BBMAP_REFORMAT.out.filtered_scaffolds, \
        //     DO_MLST.out.checked_MLSTs, \
        //     GAMMA_HV.out.gamma, \
        //     GAMMA_AR.out.gamma, \
        //     GAMMA_PF.out.gamma, \
        //     QUAST.out.report_tsv, \
        //     params.run_busco, asmbld_report, asmbld_krona_html, asmbld_k2_bh_summary, \
        //     KRAKEN2_WTASMBLD.out.report, \
        //     KRAKEN2_WTASMBLD.out.krona_html, \
        //     KRAKEN2_WTASMBLD.out.k2_bh_summary, \
        //     DETERMINE_TAXA_ID.out.taxonomy, \
        //     FORMAT_ANI.out.ani_best_hit, \
        //     CALCULATE_ASSEMBLY_RATIO.out.ratio, \
        //     AMRFINDERPLUS_RUN.out.mutation_report, \
        //     CALCULATE_ASSEMBLY_RATIO.out.gc_content, \
        //     params.extended_qc
        // )
        // ch_versions = ch_versions.mix(GENERATE_PIPELINE_STATS_WF.out.versions) 

        // // Combining output based on meta.id to create summary by sample -- is this verbose, ugly and annoying? yes, if anyone has a slicker way to do this we welcome the input.
        // line_summary_ch = GET_TRIMD_STATS.out.fastp_total_qc.map{meta, fastp_total_qc  -> [[id:meta.id], fastp_total_qc]}\
        // .join(DO_MLST.out.checked_MLSTs.map{                             meta, checked_MLSTs   -> [[id:meta.id], checked_MLSTs]},   by: [0])\
        // .join(GAMMA_HV.out.gamma.map{                                    meta, gamma           -> [[id:meta.id], gamma]},           by: [0])\
        // .join(GAMMA_AR.out.gamma.map{                                    meta, gamma           -> [[id:meta.id], gamma]},           by: [0])\
        // .join(GAMMA_PF.out.gamma.map{                                    meta, gamma           -> [[id:meta.id], gamma]},           by: [0])\
        // .join(QUAST.out.report_tsv.map{                                  meta, report_tsv      -> [[id:meta.id], report_tsv]},      by: [0])\
        // .join(CALCULATE_ASSEMBLY_RATIO.out.ratio.map{                    meta, ratio           -> [[id:meta.id], ratio]},           by: [0])\
        // .join(GENERATE_PIPELINE_STATS_WF.out.pipeline_stats.map{         meta, pipeline_stats  -> [[id:meta.id], pipeline_stats]},  by: [0])\
        // .join(DETERMINE_TAXA_ID.out.taxonomy.map{                        meta, taxonomy        -> [[id:meta.id], taxonomy]},        by: [0])\
        // .join(KRAKEN2_TRIMD.out.k2_bh_summary.map{                       meta, k2_bh_summary   -> [[id:meta.id], k2_bh_summary]},   by: [0])\
        // .join(AMRFINDERPLUS_RUN.out.report.map{                          meta, report          -> [[id:meta.id], report]},          by: [0])\
        // .join(FORMAT_ANI.out.ani_best_hit.map{                           meta, ani_best_hit    -> [[id:meta.id], ani_best_hit]},    by: [0])

        // // Generate summary per sample that passed SPAdes
        // CREATE_SUMMARY_LINE (
        //     line_summary_ch
        // )
        // ch_versions = ch_versions.mix(CREATE_SUMMARY_LINE.out.versions)

        // // Collect all the summary files prior to fetch step to force the fetch process to wait
        // failed_summaries_ch = SPADES_WF.out.line_summary.collect().ifEmpty(params.placeholder) // if no spades failure pass empty file to keep it moving...
        // // If you only run one sample and it fails spades there is nothing in the create line summary so pass an empty list to keep it moving...
        // summaries_ch = CREATE_SUMMARY_LINE.out.line_summary.collect().ifEmpty( [] )

        // // This will check the output directory for an files ending in "_summaryline_failure.tsv" and add them to the output channel
        // FETCH_FAILED_SUMMARIES (
        //     outdir_path, failed_summaries_ch, summaries_ch
        // )
        // ch_versions = ch_versions.mix(FETCH_FAILED_SUMMARIES.out.versions)

        // // combine all line summaries into one channel
        // spades_failure_summaries_ch = FETCH_FAILED_SUMMARIES.out.spades_failure_summary_line
        // fairy_summary_ch = CORRUPTION_CHECK.out.summary_line.collect().ifEmpty( [] )\
        //     .combine(GET_RAW_STATS.out.summary_line.collect().ifEmpty( [] ))\
        //     .combine(GET_TRIMD_STATS.out.summary_line.collect().ifEmpty( [] ))\
        //     .combine(SCAFFOLD_COUNT_CHECK.out.summary_line.collect().ifEmpty( [] ))\
        //     .ifEmpty( [] )

        // // pulling it all together
        // all_summaries_ch = spades_failure_summaries_ch
        //     .combine(failed_summaries_ch)
        //     .combine(summaries_ch)
        //     .combine(fairy_summary_ch)

        // // Combining sample summaries into final report
        // GATHER_SUMMARY_LINES (
        //     all_summaries_ch, params.run_busco
        // )
        // ch_versions = ch_versions.mix(GATHER_SUMMARY_LINES.out.versions)

        // //
        // // MODULE: MultiQC
        // //
        // workflow_summary    = WorkflowPhoenix.paramsSummaryMultiqc(workflow, summary_params)
        // ch_workflow_summary = Channel.value(workflow_summary)

        // ch_multiqc_files = Channel.empty()
        // ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
        // ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
        // ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
        // ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
        // ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
        // ch_multiqc_files = ch_multiqc_files.mix(FASTP_TRIMD.out.json.collect{it[1]}.ifEmpty([]))
        // ch_multiqc_files = ch_multiqc_files.mix(FASTP_SINGLES.out.json.collect{it[1]}.ifEmpty([]))
        // ch_multiqc_files = ch_multiqc_files.mix(BBDUK.out.log.collect{it[1]}.ifEmpty([]))
        // ch_multiqc_files = ch_multiqc_files.mix(QUAST.out.report_tsv.collect{it[1]}.ifEmpty([]))
        // ch_multiqc_files = ch_multiqc_files.mix(KRAKEN2_TRIMD.out.report.collect{it[1]}.ifEmpty([]))
        // ch_multiqc_files = ch_multiqc_files.mix(KRAKEN2_WTASMBLD.out.report.collect{it[1]}.ifEmpty([]))

        // MULTIQC (
        //     ch_multiqc_files.collect()
        // )
        // multiqc_report = MULTIQC.out.report.toList()
        // ch_versions    = ch_versions.mix(MULTIQC.out.versions)
    
    // emit:
    //     scaffolds        = BBMAP_REFORMAT.out.filtered_scaffolds
    //     trimmed_reads    = FASTP_TRIMD.out.reads
    //     mlst             = DO_MLST.out.checked_MLSTs
    //     amrfinder_output = AMRFINDERPLUS_RUN.out.report
    //     gamma_ar         = GAMMA_AR.out.gamma
    //     phx_summary      = GATHER_SUMMARY_LINES.out.summary_report
    //     //output for phylophoenix
    //     griphin_tsv      = params.run_griphin ? GRIPHIN.out.griphin_report : null
    //     griphin_excel    = params.run_griphin ? GRIPHIN.out.griphin_tsv_report : null
    //     dir_samplesheet  = params.run_griphin ? GRIPHIN.out.converted_samplesheet : null
}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/
// // Adding if/else for running on ICA
//     workflow.onComplete {
//         if (count == 0) {
//             if (params.email || params.email_on_fail) {
//                 NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
//             }
//             NfcoreTemplate.summary(workflow, params, log)
//             count++
//         }
/*
========================================================================================
    THE END
========================================================================================
*/
