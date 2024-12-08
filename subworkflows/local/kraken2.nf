//
// Subworkflow: run Kraken2
//

include { KRAKEN2_KRAKEN2                               } from '../../modules/local/kraken2'
include { KRAKEN_BEST_HIT                               } from '../../modules/local/kraken_bh'

workflow KRAKEN2_WF {
    take:
    fasta           // channel: tuple (meta) path(read_R1, reads_R2) or tuple (meta) path(scaffolds)
    fairy_check     // GET_RAW_STATS.out.outcome or SCAFFOLD_COUNT_CHECK.out.outcome
    type            // val: trimd, asmbld or wtasmbld 
    qc_stats        //GATHERING_READ_QC_STATS.out.fastp_total_qc
    kraken2_db_path

    main:
    ch_versions     = Channel.empty() // Used to collect the software versions

    // add in fairy to confirm reads are uncorrupted and correct
    fasta_ch = fasta.join(fairy_check.splitCsv(strip:true, by:5).map{meta, fairy_outcome -> [meta, [fairy_outcome[0][0], fairy_outcome[1][0], fairy_outcome[2][0]]]}, by: [0,0])\
        .combine(kraken2_db_path)

    // Checking for Contamination in trimmed reads
    KRAKEN2_KRAKEN2 (
        fasta_ch, 
        type, 
        params.save_output_fastqs, 
        params.save_reads_assignment
    )
    ch_versions = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions)
    ch_report = KRAKEN2_KRAKEN2.out.report

    // Combining kraken report with quast report based on meta.id
    kraken_bh_ch = ch_report.map{meta, report         -> [[id:meta.id], report]}\
        .join(qc_stats.map{ meta, fastp_total_qc -> [[id:meta.id], fastp_total_qc]}, by: [0])
        
    // Getting Kraken best hit for assembled data
    KRAKEN_BEST_HIT (
        kraken_bh_ch, type
    )
    ch_versions = ch_versions.mix(KRAKEN_BEST_HIT.out.versions)
    ch_k2_besthit = KRAKEN_BEST_HIT.out.ksummary

    emit:
    report          = ch_report
    k2_bh_summary   = ch_k2_besthit
    versions        = ch_versions // channel: [ versions.yml ]
}