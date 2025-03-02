import csv
import pandas as pd
import os

def get_fastqc_output():
    qc_fastqc_outputs = list(
        expand(
            "data/{assay}_{experiment}/{library}/{sample}/fastqc/{sample}_R1_fastqc.html", 
            zip,
            assay=metadata.Assay.to_list(),
            experiment=metadata.ExperimentName.to_list(),
            library=metadata.LibraryName.to_list(),
            sample=metadata.SampleName.to_list(),
            seacr_cutoff=metadata.SeacrCutoff.to_list()
            )
    ) + list(
        expand(
            "data/{assay}_{experiment}/{library}/{sample}/fastqc/{sample}_R2_fastqc.html", 
            zip,
            assay=metadata.Assay.to_list(),
            experiment=metadata.ExperimentName.to_list(),
            library=metadata.LibraryName.to_list(),
            sample=metadata.SampleName.to_list(),
            seacr_cutoff=metadata.SeacrCutoff.to_list()
            )
    )
    return qc_fastqc_outputs

def get_report_output():
    qc_report_outputs = list(
        expand(
            "data/{assay}_{experiment}/{library}/{sample}/report/{sample}_top{seacr_cutoff}_qc_report.html", 
            zip,
            assay=metadata.Assay.to_list(),
            experiment=metadata.ExperimentName.to_list(),
            library=metadata.LibraryName.to_list(),
            sample=metadata.SampleName.to_list(),
            seacr_cutoff=metadata.SeacrCutoff.to_list()
            )
    ) + list(
        expand(
            "data/{assay}_{experiment}/{library}/{sample}/report/{sample}_top{seacr_cutoff}_qc_metrics.json", 
            zip,
            assay=metadata.Assay.to_list(),
            experiment=metadata.ExperimentName.to_list(),
            library=metadata.LibraryName.to_list(),
            sample=metadata.SampleName.to_list(),
            seacr_cutoff=metadata.SeacrCutoff.to_list()
            )
    )
    return qc_report_outputs

def get_bigwig_output():
    bigwig_outputs = list(
        expand(
            "data/{assay}_{experiment}/{library}/{sample}/alignment/bigwig/{sample}_bowtie2.bw",
            zip,
            assay=metadata.Assay.to_list(),
            experiment=metadata.ExperimentName.to_list(),
            library=metadata.LibraryName.to_list(),
            sample=metadata.SampleName.to_list(),
            seacr_cutoff=metadata.SeacrCutoff.to_list()
            )
    )
    return bigwig_outputs

def get_seacr_output():
    seacr_outputs = list(
        expand("data/{assay}_{experiment}/{library}/{sample}/peakCalling/peakCalling/deeptools/{sample}_top{seacr_cutoff}_frip.txt", 
               zip,
               assay=metadata.Assay.to_list(),
               experiment=metadata.ExperimentName.to_list(),
               library=metadata.LibraryName.to_list(),
               sample=metadata.SampleName.to_list(),
               seacr_cutoff=metadata.SeacrCutoff.to_list()
               )
    )
    return seacr_outputs

def create_symlink(target, link_name):
    if not os.path.exists(link_name):
        os.symlink(target, link_name)
        print(f"Created symlink: {link_name} -> {target}")
    else:
        print(f"Symlink already exists: {link_name}")

# ## Debug
# from snakemake.io import expand
# import yaml
# with open ('config/config.yaml') as f:
#     config = yaml.safe_load(f)

metadata = (
    pd.read_csv(
        config["metadata"], 
        dtype={'ExperimentName': str, 'LibraryName': str, 'SampleName': str, 'SeqRun': str,  'Assay': str,
               'Read1': str, 'Read2': str, 'OutputDir': str, 'SeacrCutoff': str})
        .set_index("ExperimentName", drop=False)
        .sort_index()
)

# Filter out entries with partial information and non-CUTTag assays
metadata = metadata.dropna(subset=['Read1', 'Read2'], how='any')
metadata = metadata[metadata['Assay'].isin(['NanoCT', 'CUTTag'])]

for _, row in metadata.iterrows():
        experiment_name = row['ExperimentName']
        library_name = row['LibraryName']
        sample_name = row['SampleName']
        assay = row['Assay']
        read1_path = row['Read1']
        read2_path = row['Read2']
        output_path = row['OutputDir']

        # Create output path if not exists
        if not os.path.exists(output_path):
            os.makedirs(output_path, exist_ok=True)
            print(f"Created output dir: {output_path}")

        # Create library directory
        library_dir = os.path.join(output_path, library_name)
        if not os.path.exists(library_dir):
            os.makedirs(library_dir, exist_ok=True)
            print(f"Created library dir: {library_dir}")

        # Create sample directory
        sample_dir = os.path.join(library_dir, sample_name)
        if not os.path.exists(sample_dir):
            os.makedirs(sample_dir, exist_ok=True)
            print(f"Created sample dir: {sample_dir}")

        # Create fastq directory and symlink to rawdata
        fastq_path = os.path.join(sample_dir, 'fastq')
        if not os.path.exists(fastq_path):
            os.makedirs(fastq_path, exist_ok=True)
            print(f"Created fastq dir, symlink to rawdata: {fastq_path}")

        create_symlink(read1_path, os.path.join(fastq_path, os.path.basename(read1_path)))
        create_symlink(read2_path, os.path.join(fastq_path, os.path.basename(read2_path)))

        # Create modality-experiment directory in data folder
        experiment_dir = os.path.join('data', assay+'_'+experiment_name)
        if not os.path.exists(experiment_dir):
            os.makedirs(experiment_dir, exist_ok=True)
            print(f"Created experiment dir in data folder: {experiment_dir}")

        # Create symlink in data folder
        data_symlink = os.path.join('data', assay+'_'+experiment_name, library_name)
        create_symlink(os.path.join(output_path, library_name), data_symlink)
