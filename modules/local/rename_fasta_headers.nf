process RENAME_FASTA_HEADERS {
    tag "$meta.id"
    label 'process_low'
    // base_v2.1.0 - MUST manually change below (line 21)!!!
    container 'quay.io/jvhagey/phoenix@sha256:f0304fe170ee359efd2073dcdb4666dddb96ea0b79441b1d2cb1ddc794de4943'

    input:
    tuple val(meta), path(assembled_scaffolds)

    output:
    tuple val(meta), path('*.renamed.scaffolds.fa.gz'), emit: renamed_scaffolds
    path "versions.yml"                               , emit: versions

    script: // This script is bundled with the pipeline, in cdcgov/phoenix/bin/
    // define variables
    def prefix = task.ext.prefix ?: "${meta.id}"
    def container_version = "base_v2.1.0"
    def container = task.container.toString() - "quay.io/jvhagey/phoenix@"
    def script = "rename_fasta_headers.py"
    """
    gunzip --force ${assembled_scaffolds}
    unzipped=\$(basename ${assembled_scaffolds} .gz) #adding this in to allow alternative file names with -entry SCAFFOLDS --scaffolds_ext

    ${script} --input \$unzipped --output ${prefix}.renamed.scaffolds.fa --name ${prefix}

    gzip --force ${prefix}.renamed.scaffolds.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        rename_fasta_headers.py: \$(${script} --version )
        phoenix_base_container_tag: ${container_version}
        phoenix_base_container: ${container}
    END_VERSIONS
    """
}