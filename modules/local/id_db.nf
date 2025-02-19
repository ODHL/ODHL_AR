process ID_DB {
    label 'process_single'

    input:
    path(core_functions_script)
    path(quality_results)
    path(idDB_file)

    output:
    path('wgs_db_results.csv')               , emit: wgs_results
    path("versions.yml")                     , emit: versions

    script:
    """
    cat $quality_results | awk '{print \$1}' > sample_list.csv

    core_ids.sh \
        $core_functions_script \
        sample_list.csv \
        $idDB_file
        
    cat <<-END_VERSIONS >> versions.yml
    "${task.process}":
        version: v1.0
    END_VERSIONS
    """
}