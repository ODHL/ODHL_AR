process NCBI_PREP {
    label 'process_single'

    input:
    path(core_functions_script)
    val(project_id)
    path(metadata_file)
    path(ncbiConfig)
    path(ncbiDB_file)
    path(sample_list)
    path(pipeline_results)
    path(wgsDB_results)

    output:
    path('ncbi_sample_list.csv')               , emit: ncbi_sample_list
    path("versions.yml")                       , emit: versions

    script:
    """
    core_ncbi_prep.sh \
        $core_functions_script \
        $project_id \
        $metadata_file \
        $ncbiConfig \
        $ncbiDB_file \
        $sample_list \
        $pipeline_results \
        $wgsDB_results
    """
}