# bulkCT_smkpipe

This repository hosts a Snakemake pipeline designed for efficient and reproducible batch processing of bulk CUT&Tag data.

This pipeline is based on [CUT&Tag Data Processing and Analysis Tutorial](https://yezhengstat.github.io/CUTTag_tutorial/) with slightly modified workflows.

## Running the pipeline

### Step 1: Fill in `config/metadata.csv`.

### Step 2: Open terminal and execute the following commands:
```
luolab@luolab-X11DAi-N:~/GITHUB_REPOS/bulkCT_smkpipe$ conda activate snakemake
(snakemake) luolab@luolab-X11DAi-N:~/GITHUB_REPOS/bulkCT_smkpipe$ snakemake --use-conda --cores 72 --dry-run
(snakemake) luolab@luolab-X11DAi-N:~/GITHUB_REPOS/bulkCT_smkpipe$ snakemake --use-conda --cores 72
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