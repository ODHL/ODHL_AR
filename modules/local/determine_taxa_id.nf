process DETERMINE_TAXA_ID {
    tag "$meta.id"
    label 'process_single'
    // base_v2.1.0 - MUST manually change below (line 25)!!!
    container 'quay.io/jvhagey/phoenix@sha256:f0304fe170ee359efd2073dcdb4666dddb96ea0b79441b1d2cb1ddc794de4943'

    input:
    tuple val(meta), path(kraken_weighted), path(formatted_ani_file), path(k2_bh_summary)
    path(nodes_file)
    path(names_file)

    output:
    tuple val(meta), path('*.tax'), emit: taxonomy
    path("versions.yml")          , emit: versions

    script: // This script is bundled with the pipeline, in cdcgov/phoenix/bin/
    // define variables
    def prefix = task.ext.prefix ?: "${meta.id}"
    // -r needs to be last as in -entry SCAFFOLDS/CDC_SCAFFOLDS k2_bh_summary is not passed so its a blank argument
    def k2_bh_file = k2_bh_summary ? "-r $k2_bh_summary" : ""
    def container_version = "base_v2.1.0"
    def container = task.container.toString() - "quay.io/jvhagey/phoenix@"
    def script = "determine_taxID.sh"
    """
    ${script} -k $kraken_weighted -s $meta.id -f $formatted_ani_file -d $nodes_file -m $names_file $k2_bh_file

    script_version=\$(${script} -V)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        NCBI_Taxonomy_Nodes_Reference_File: $nodes_file
        NCBI_Taxonomy_Names_Reference_File: $names_file
        phoenix_base_container_tag: ${container_version}
        phoenix_base_container: ${container}
        \${script_version}
    END_VERSIONS
    """
}