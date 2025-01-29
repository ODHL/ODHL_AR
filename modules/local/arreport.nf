process arREPORT {
    label 'process_single'

    input:
    path(pipelineResults)
    path(ch_ncbi_output)

    output:
    path('ncbi_resultIDs.csv')               , emit: ncbi_output
    path("versions.yml")                     , emit: versions

    script:
    """
    core_ncbi_post.sh \
        $project_id \
        $ncbiDB_file \
        $wgsDB_file \
        $sample_list
    """
}