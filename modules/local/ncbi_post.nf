process NCBI_POST {
    label 'process_single'

    input:
    val(project_id)
    path(ncbiDB_file)
    path(wgsDB_file)
    path(sample_list)

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