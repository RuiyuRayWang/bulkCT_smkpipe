library(rmarkdown)
library(jsonlite)
library(dplyr)
library(ggplot2)

# Define the path to the JSON files
json_files <- list.files(path = "data", pattern = "*_qc_metrics.json",
                         recursive = TRUE, full.names = TRUE)

# Read and combine all JSON files into a single data frame
qc_metrics_list <- lapply(json_files, fromJSON)
qc_metrics_df <- bind_rows(qc_metrics_list)

# Define the output directory
output_dir <- "../reports"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Render the RMarkdown file
render(
  input = "reports/qc_summary_template.Rmd",
  output_file = paste0(output_dir, "/qc_summary_report.html"),
  params = list(qc_metrics = qc_metrics_df),
  envir = new.env(parent = globalenv())
)
