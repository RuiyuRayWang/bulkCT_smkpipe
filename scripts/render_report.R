library(rmarkdown)

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
assay <- args[1]
experiment <- args[2]
library <- args[3]
sample <- args[4]

# Define the parameters
params <- list(
  title = paste("QC Report for", assay, sample),
  assay = assay,
  experiment = experiment,
  library = library,
  sample = sample
)

# Specify the output directory
output_dir <- paste0("../data/", assay, "_", experiment,
                     "/", library, "/", sample, "/report")
# if (!dir.exists(output_dir)) {
#   dir.create(output_dir, recursive = TRUE)
# }

# Render the RMarkdown file
render(
  input = "reports/report_template.Rmd",
  output_file = paste0(output_dir, "/", sample, "_", "qc_report.html"),
  params = params,
  envir = new.env(parent = globalenv())
)
