process WGS_DB {
    label 'process_single'

    input:
    path(core_functions_script)
    path(sample_list)
    path(wgsDB_file)

    output:
    path('wgs_db_results.csv')               , emit: wgs_results
    path("versions.yml")                     , emit: versions

    script:
    """
    core_wgs.sh \
        $core_functions_script \
        $sample_list \
        $wgsDB_file
        
    cat <<-END_VERSIONS >> versions.yml
    "${task.process}":
        version: v1.0
    END_VERSIONS
    """
}