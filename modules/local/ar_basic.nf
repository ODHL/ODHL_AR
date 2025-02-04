process REPORT_BASIC {
    tag "REPORT_BASIC"
    label 'process_high'

    container 'ghcr.io/slsevilla/basic_rpeort:latest'

  input:
    path(core_functions_script)
    path(basic_RMD)
    val(project_id)
    path(analyzer_results)
    path(ncbiDB_file)
    path(wgsDB_file)
    path(all_geneFiles)

  output:
    path('*.html')                  , emit: HTMLreport
    path("final_report.csv")        , emit: CSVreport
    path("ar_predictions.csv")      , optional:true, emit: predictions

  script:
  """
  bash core_report_basic.sh \
    $core_functions_script \
    $basic_RMD \
    $project_id \
    $analyzer_results \
    $ncbiDB_file \
    $wgsDB_file \
  
  Rscript -e 'rmarkdown::render("${basic_RMD}", output_file="basic.html", output_dir = getwd())'
  """
}