process REPORT_BASIC {
    tag "REPORT_BASIC"
    label 'process_high'

    container 'ghcr.io/slsevilla/report:latest'

  input:
    path(updated_basicRMD)
    val(projectID)
    path(final_report)
    path(predictions)
    path(config_arReport)
    path(odhl_logo)

  output:
    path('*.html')                  , emit: HTMLreport

  script:
  """
  Rscript -e 'rmarkdown::render("${updated_basicRMD}", output_file="${projectID}_basicReport.html", output_dir = getwd())'
  """
}