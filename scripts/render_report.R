library(rmarkdown)

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
assay <- args[1]
experiment <- args[2]
library <- args[3]
sample <- args[4]
seacr_cutoff <- args[5]

# Define the parameters
params <- list(
  title = paste("QC Report for", assay, sample),
  assay = assay,
  experiment = experiment,
  library = library,
  sample = sample,
  seacr_cutoff = seacr_cutoff
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
  output_file = paste0(
    output_dir, "/", sample, "_top", seacr_cutoff, "_qc_report.html"
  ),
  params = params,
  envir = new.env(parent = globalenv())
)
