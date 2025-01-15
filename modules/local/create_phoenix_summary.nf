process CREATE_PHOENIX_SUMMARY {
    label 'process_single'
    // base_v2.1.0 - MUST manually change below (line 22)!!!
    container 'quay.io/jvhagey/phoenix@sha256:f0304fe170ee359efd2073dcdb4666dddb96ea0b79441b1d2cb1ddc794de4943'

    input:
    path(summary_line_files)
    val(busco_val)

    output:
    path('Phoenix_Summary.tsv'), emit: summary_report
    path("versions.yml")             , emit: versions

    script: // This script is bundled with the pipeline, in cdcgov/phoenix/bin/
    // define variables
    def busco_parameter = busco_val ? "--busco" : ""
    def container_version = "base_v2.1.0"
    """
    create_phoenix_summary_tsv.py \\
        --out Phoenix_Summary.tsv \\
        $busco_parameter

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        phoenix_base_container_tag: ${container_version}
    END_VERSIONS
    """
}
