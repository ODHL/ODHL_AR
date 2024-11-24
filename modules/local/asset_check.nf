process ASSET_CHECK {
    label 'process_low'
    container 'quay.io/jvhagey/phoenix@sha256:f0304fe170ee359efd2073dcdb4666dddb96ea0b79441b1d2cb1ddc794de4943'

    input:
    path(kraken_db)

    output:
    path("versions.yml"), emit: versions
    path('*_folder'),     emit: kraken_db

    when:
    task.ext.when == null || task.ext.when

    script:
    def container_version = "base_v2.1.0"
    def container = task.container.toString() - "quay.io/jvhagey/phoenix@"
    """
    if [[ ${kraken_db} = *.tar.gz ]]
    then
        folder_name=\$(basename ${kraken_db} .tar.gz)
        tar --use-compress-program="pigz -vdf" -xf ${kraken_db}
        mkdir \${folder_name}_folder
        mv *.kmer_distrib \${folder_name}_folder
        mv *.k2d \${folder_name}_folder
        mv seqid2taxid.map \${folder_name}_folder
        mv inspect.txt \${folder_name}_folder
        mv ktaxonomy.tsv \${folder_name}_folder
    else
        folder_name=\$(basename ${kraken_db} .tar.gz)
        mv \${folder_name} \${folder_name}_folder
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        phoenix_base_container_tag: ${container_version}
        phoenix_base_container: ${container}
    END_VERSIONS
    """
}