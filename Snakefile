configfile: "config/config.yaml"

include: "rules/common.smk"
include: "rules/pipeline.smk"

rule all:
    input:
        # Final outputs
        get_final_output(),
        # get_seacr_output(),
        "reports/qc_summary_report.html"