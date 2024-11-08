process BASESPACE {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta)

    output:
    tuple val(meta), path("*gz"), emit: reads

    script:
    // Extract sampleID from meta.id
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    # download files 
    ~/tools/basespace download biosample -n ${prefix}
    
    # Grab R1, R2 names
    R1=\$(ls ${prefix}*ds*/*R1* | head -n1)
    R2=\$(ls ${prefix}*ds*/*R2* | head -n1)
    
    # Rename output files
    sample_id=`echo ${prefix} | cut -f1 -d"-"`
    mv \$R1 .
    mv \$R2 .

    
    """

    stub:
    """
    touch \${sample_id}.R1.fastq.gz
    touch \${sample_id}.R2.fastq.gz
    """
}
