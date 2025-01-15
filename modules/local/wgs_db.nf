process WGS_DB {
    label 'process_single'
    // base_v2.1.0 - MUST manually change below (line 22)!!!
    container 'quay.io/jvhagey/phoenix@sha256:f0304fe170ee359efd2073dcdb4666dddb96ea0b79441b1d2cb1ddc794de4943'

    input:
    path(core_functions_script)
    path(phoenix_results)
    path(wgs_db_master)

    output:
    path('*.csv')         , emit: wgs_results
    path("versions.yml")                , emit: versions

    script: // This script is bundled with the pipeline, in cdcgov/phoenix/bin/
    // define variables
    """
    core_wgs.sh \
        $core_functions_script \
        $phoenix_results \
        $wgs_db_master \
        pipeline_results_wgs.csv
    """
}


    //     output_dir=$1
    //     project_name_full=$2
    //     wgs_results=$3
    //     pipeline_results=$4
    //     pipeline_log=$5

    // create_phoenix_summary_tsv.py \\
    //     --out Phoenix_Summary.tsv \\
    //     $busco_parameter

    // cat <<-END_VERSIONS > versions.yml
    // "${task.process}":
    //     python: \$(python --version | sed 's/Python //g')
    //     phoenix_base_container_tag: ${container_version}
    // END_VERSIONS
