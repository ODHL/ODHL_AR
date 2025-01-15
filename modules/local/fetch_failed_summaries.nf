process FETCH_FAILED_SUMMARIES {
    label 'process_single'
    // base_v2.1.0 - MUST manually change below (line 16)!!!
    container 'quay.io/jvhagey/phoenix@sha256:f0304fe170ee359efd2073dcdb4666dddb96ea0b79441b1d2cb1ddc794de4943'

    input:
    path(failed_summaries)
    path(summaries)

    output:
    path('*_summaryline.tsv'), emit: spades_failure_summary_line
    path("versions.yml")     , emit: versions

    script:
    def container_version = "base_v2.1.0"
    def container = task.container.toString() - "quay.io/jvhagey/phoenix@"
    """
    touch empty_summaryline.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        phoenix_base_container_tag: ${container_version}
        phoenix_base_container: ${container}
    END_VERSIONS
    """
}