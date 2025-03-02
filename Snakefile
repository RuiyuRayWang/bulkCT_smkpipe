configfile: "config/config.yaml"

include: "rules/common.smk"
include: "rules/pipeline.smk"

rule all:
    input:
        # Final outputs
        get_fastqc_output(),
        get_bigwig_output(),
        get_report_output(),
        # get_seacr_output(),
        "reports/qc_summary_report.html"