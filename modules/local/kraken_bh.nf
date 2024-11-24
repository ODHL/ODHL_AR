process KRAKEN_BEST_HIT {
    tag "$meta.id"
    label 'process_single'
    // base_v2.1.0 - MUST manually change below (line 26)!!!
    container 'quay.io/jvhagey/phoenix@sha256:f0304fe170ee359efd2073dcdb4666dddb96ea0b79441b1d2cb1ddc794de4943'

    input:
    tuple val(meta), path(kraken_summary), path(count_file) //[-q count_file (reads or congtigs)] so quast report for assembled or output of GATHERING_READ_QC_STATS for trimmed
    val(kraken_type) //weighted, trimmmed or assembled

    output:
    tuple val(meta), path('*.top_kraken_hit.txt'), emit:ksummary
    path("versions.yml")           , emit: versions

    script: // This script is bundled with the pipeline, in cdcgov/phoenix/bin/
    // define variables
    def prefix = task.ext.prefix ?: "${meta.id}"
    def container_version = "base_v2.1.0"
    def container = task.container.toString() - "quay.io/jvhagey/phoenix@"
    def script = params.ica ? "${params.ica_path}/kraken2_best_hit.sh" : "kraken2_best_hit.sh"
    def terra = params.terra ? "-t terra" : ""
    """
    ${script} -i $kraken_summary -q $count_file -n ${prefix} $terra

    script_version=\$(${script} -V)

    mv ${prefix}.summary.txt ${prefix}.kraken2_${kraken_type}.top_kraken_hit.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        phoenix_base_container_tag: ${container_version}
        phoenix_base_container: ${container}
        \${script_version}
    END_VERSIONS
    """
}