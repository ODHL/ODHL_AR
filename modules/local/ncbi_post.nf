process NCBI_POST {
    label 'process_single'

    input:
    val(project_id)
    path(idDB_file)
    path(ncbi_pre_file)
    path(ncbi_output_file)

    output:
    path("versions.yml")                        , emit: versions
    path("id_db_results_postNCBI.csv")           , emit: ncbi_post_file

    script:
    """
    core_ncbi_post.sh \
        $project_id \
        $idDB_file \
        $ncbi_pre_file \
        $ncbi_output_file

    cat <<-END_VERSIONS >> versions.yml
    "${task.process}":
        post_process_tag: "v1.0"
    END_VERSIONS

    """
}