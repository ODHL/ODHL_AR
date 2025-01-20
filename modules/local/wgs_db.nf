process WGS_DB {
    label 'process_single'

    input:
    path(core_functions_script)
    path(sample_list)
    path(wgsDB_file)

    output:
    path('wgs_db_master.csv')               , emit: wgs_results
    path("versions.yml")                    , emit: versions

    script:
    """
    core_wgs.sh \
        $core_functions_script \
        $sample_list \
        $wgsDB_file
    """
}