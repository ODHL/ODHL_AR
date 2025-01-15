process POST_PROCESS {
    label 'process_single'

    input:
    path(trimmed_read_counts_files_ch)
    path(final_phoenix_summary)
    path(core_functions_script)
    // path(phoenix_results)

    output:
    path('pipeline_results.csv')         , emit: pipeline_results
    path('processed_samples.csv')        , emit: processed_samples
    path("versions.yml")                , emit: versions

    script: // This script is bundled with the pipeline, in cdcgov/phoenix/bin/
    // define variables
    """
    post_process.sh \
        $core_functions_script \
        $final_phoenix_summary
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

// # create a pass list
// awk '{print $1","$2}' $phoenix_results | grep - "FAIL"
// 24AR003724-OH-VH00648-240920,FAIL
// 24AR004033-OH-VH00648-241004,FAIL
