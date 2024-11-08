process CORRUPTION_CHECK {
    tag "${meta.id}"
    label 'process_medium'
    // base_v2.1.0 - MUST manually change below (line 28)!!!
    container 'quay.io/jvhagey/phoenix@sha256:f0304fe170ee359efd2073dcdb4666dddb96ea0b79441b1d2cb1ddc794de4943'

    input:
    tuple val(meta), path(reads)
    val(busco_val)

    output:
    tuple val(meta), path('*_summary_fairy.txt'),              emit: outcome
    path('*_summaryline.tsv'),                  optional:true, emit: summary_line
    tuple val(meta), path('*.synopsis'),        optional:true, emit: synopsis
    path("versions.yml"),                                      emit: versions

    script:
    // define variables
    def prefix = task.ext.prefix ?: "${meta.id}"
    def num1 = "${reads[0]}".minus(".fastq.gz")
    def num2 = "${reads[1]}".minus(".fastq.gz")
    def busco_parameter = busco_val ? "-b" : ""
    def container_version = "base_v2.1.0"
    def container = task.container.toString() - "quay.io/jvhagey/phoenix@"
    def script = params.ica ? "python ${params.ica_path}/fairy_proc.sh" : "fairy_proc.sh"
"""
    #set +e
    #check for file integrity and log errors
    #if there is a corruption problem the script will create a *_summaryline.tsv and *.synopsis file for the sample.
    ${script} -r ${reads[0]} -p ${prefix} ${busco_parameter}
    ${script} -r ${reads[1]} -p ${prefix} ${busco_parameter}

    script_version=\$(${script} -V)

    #making a copy of the summary file to pass to READ_COUNT_CHECKS to handle file names being the same
    mv ${prefix}_summary.txt ${prefix}_summary_fairy.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        phoenix_base_container_tag: ${container_version}
        phoenix_base_container: ${container}
        \${script_version}
    END_VERSIONS
    """
}