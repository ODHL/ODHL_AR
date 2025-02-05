process REPORT_BASIC {
    tag "REPORT_BASIC"
    label 'process_high'

    container 'ghcr.io/slsevilla/basic_report:latest'

  input:
    path(updated_basicRMD)
    val(project_id)
    path(final_report)
    path(ch_predictions)
    path(config_arReport)
    path(odhl_logo)

  output:
    path('*.html')                  , emit: HTMLreport

  script:
  """
  Rscript -e 'rmarkdown::render("${updated_basicRMD}", output_file="${project_id}_basicReport.html", output_dir = getwd())'
  """
}