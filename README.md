# bulkCT_smkpipe

This repository hosts a Snakemake pipeline designed for efficient and reproducible batch processing of bulk CUT&Tag data.

This pipeline is based on [CUT&Tag Data Processing and Analysis Tutorial](https://yezhengstat.github.io/CUTTag_tutorial/) with slightly modified workflows.

## Requirements

This pipeline is developed with snakemake version `8.27.1`. Two conda environments are required: `snakemake` and `epigenomics`.

Install `snakemake` into a dedicated conda environment. 
```
conda create -n snakemake python=3.12.8
conda env update -n snakemake --file envs/snakemake.yaml
```

Additionally, a second conda environment `epigenomics` is required.
```
conda create -n epigenomics python=3.8.13
conda env update -n epigenomics --file envs/epigenomics/yaml
```

The following required packages need to be installed by root:
```
pandoc  # v2.5
bowtie2  # v2.3.5.1, 64-bit
picard  # picard.jar
samtools  # v1.3.1
bedtools  # v2.27.1
R  # v4.4.3 (2025-02-28)
```

R packages:
```
install.packages("tidyverse")
install.packages("rmarkdown")
install.packages("viridis")
install.packages("ggpubr")
install.packages("jsonlite")
install.packages("DT")
install.packages("languageserver")  # for R extension in VSCode
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install("DESeq2")
```

## Running the pipeline

### Step 1: Fill in `config/metadata.csv`.

### Step 2: Open terminal and execute the following commands:
```
conda activate snakemake
snakemake --use-conda --cores 72 --dry-run
snakemake --use-conda --cores 72
```

Goto D1D2_ENHANCER project directory for further downstream analysis (i.e. peak analysis).

## Folder Structure

```
├── config
│   ├── config.yaml
│   └── metadata.csv
|
├── data
│
├── envs
│   └── epigenomics.yaml
|
├── LICENSE
|
├── misc
│   ├── CUTTag_pipeline_noSpikeIn.txt
│   ├── CUTTag.R
│   └── scratch1.R
|
├── README.md
|
├── reports
│   ├── qc_summary_report.html
│   ├── qc_summary_template.Rmd
│   └── report_template.Rmd
|
├── results
|
├── rules
│   ├── common.smkSimplified
├── scripts
│   ├── gather_qc_metrics.R
│   └── render_report.R
|
└── Snakefile
```

## Rulegraph

The following command generates a rulegraph of the pipeline for intuitive visualizations:
```
snakemake --rulegraph | grep -v "Symlink" | dot -Tpng -o rulegraph.png
```

<p align="center">
  <img width="480"  src="https://github.com/RuiyuRayWang/bulkCT_smkpipe/blob/master/rulegraph.png">
</p>

## TODO

- [ ] Update README to include package installation guide.
- [x] Write folder ftructure
- [x] Refactor code to include adapter trimming.
- [ ] Migrate to HPC.
- [ ] Add `dirs.py` in utils for creating directories.