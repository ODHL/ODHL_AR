process REPORT_PREP {
    tag "REPORT_PREP"
    label 'process_low'

    input:
        path(core_functions_script)
        path(basic_RMD)
        val(project_id)
        path(analyzer_results)
        path(ncbiDB_file)
        path(wgsDB_file)
        path(all_geneFiles)

    output:
        path("final_report.csv")        , emit: CSVreport
        path("ar_predictions.tsv")      , emit: predictions
        path("*_basicReport.Rmd")       , emit: RMD

    script:
    """
    # prep the report file
    cp $basic_RMD ${project_id}_basicReport.Rmd
    
    # prep the final report and RMD file
    bash core_report_prep.sh \
        $core_functions_script \
        ${project_id}_basicReport.Rmd \
        $project_id \
        $analyzer_results \
        $ncbiDB_file \
        $wgsDB_file \
    """
}