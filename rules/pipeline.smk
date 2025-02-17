rule qc_fastqc:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/fastq/{sample}_R1.fq.gz",
        "data/{assay}_{experiment}/{library}/{sample}/fastq/{sample}_R2.fq.gz"
    output:
        "data/{assay}_{experiment}/{library}/{sample}/fastqc/{sample}_R1_fastqc.html",
        "data/{assay}_{experiment}/{library}/{sample}/fastqc/{sample}_R2_fastqc.html"
    conda:
        "epigenomics"
    threads:
        32
    shell:
        """
        fastqc -t 32 {input} -o data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/fastqc
        """

rule bowtie2_alignment:
    input:
        r1="data/{assay}_{experiment}/{library}/{sample}/fastq/{sample}_R1.fq.gz",
        r2="data/{assay}_{experiment}/{library}/{sample}/fastq/{sample}_R2.fq.gz"
    output:
        sam=protected("data/{assay}_{experiment}/{library}/{sample}/alignment/sam/{sample}_bowtie2.sam"),
        summary="data/{assay}_{experiment}/{library}/{sample}/alignment/sam/bowtie2_summary/{sample}_bowtie2.txt"
    params:
        cores=config["cores"],
        ref=config["RefGenome"]
    conda:
        "epigenomics"
    threads:
        32
    shell:
        """
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/alignment/sam/bowtie2_summary
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/alignment/bam
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/alignment/bed
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/alignment/bedgraph
        bowtie2 --end-to-end --very-sensitive \
                --no-mixed --no-discordant \
                --phred33 -I 10 -X 700 \
                -p {params.cores} \
                -x {params.ref} \
                -1 {input.r1} -2 {input.r2} \
                -S {output.sam} &> {output.summary}
        """

rule sort_sam:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/sam/{sample}_bowtie2.sam"
    output:
        temp("data/{assay}_{experiment}/{library}/{sample}/alignment/sam/{sample}_bowtie2.sorted.sam")
    params:
        picard=config["picard"]
    conda:
        "epigenomics"
    shell:
        """
        java -jar {params.picard} SortSam \
            I={input} \
            O={output} \
            SORT_ORDER=coordinate
        """

rule mark_duplicates:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/sam/{sample}_bowtie2.sorted.sam"
    output:
        temp("data/{assay}_{experiment}/{library}/{sample}/alignment/removeDuplicate/{sample}_bowtie2.sorted.dupMarked.sam"),
        "data/{assay}_{experiment}/{library}/{sample}/alignment/removeDuplicate/picard_summary/{sample}_picard.dupMark.txt"
    params:
        picard=config["picard"]
    conda:
        "epigenomics"
    shell:
        """
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/alignment/removeDuplicate/picard_summary
        java -jar {params.picard} MarkDuplicates \
            I={input} \
            O={output[0]} \
            METRICS_FILE={output[1]}
        """

rule remove_duplicates:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/sam/{sample}_bowtie2.sorted.sam"
    output:
        temp("data/{assay}_{experiment}/{library}/{sample}/alignment/removeDuplicate/{sample}_bowtie2.sorted.rmDup.sam"),
        "data/{assay}_{experiment}/{library}/{sample}/alignment/removeDuplicate/picard_summary/{sample}_picard.rmDup.txt"
    params:
        picard=config["picard"]
    conda:
        "epigenomics"
    shell:
        """
        java -jar {params.picard} MarkDuplicates \
            I={input} \
            O={output[0]} \
            REMOVE_DUPLICATES=true \
            METRICS_FILE={output[1]}
        """

rule fragment_size_distribution:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/sam/{sample}_bowtie2.sam"
    output:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/sam/fragmentLen/{sample}_fragmentLen.txt"
    conda:
        "epigenomics"
    shell:
        """
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/alignment/sam/fragmentLen
        samtools view -F 0x04 {input} | awk -F'\\t' 'function abs(x){{return ((x < 0.0) ? -x : x)}} {{print abs($9)}}' | \
        sort | uniq -c | awk -v OFS="\\t" '{{print $2, $1/2}}' > {output}
        """

rule filter_quality_reads:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/sam/{sample}_bowtie2.sam"
    output:
        temp("data/{assay}_{experiment}/{library}/{sample}/alignment/sam/{sample}_bowtie2.qualityScore2.sam")
    params:
        cores=config["cores"]
    conda:
        "epigenomics"
    threads:
        32
    shell:
        """
        samtools view -h -q 2 {input} > {output} -@ {params.cores}
        """

rule sam_to_bam:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/sam/{sample}_bowtie2.qualityScore2.sam"
    output:
        bam=protected("data/{assay}_{experiment}/{library}/{sample}/alignment/bam/{sample}_bowtie2.mapped.bam"),
        idx="data/{assay}_{experiment}/{library}/{sample}/alignment/bam/{sample}_bowtie2.mapped.sorted.bam.bai",
        sorted_bam="data/{assay}_{experiment}/{library}/{sample}/alignment/bam/{sample}_bowtie2.mapped.sorted.bam"
    params:
        cores=config["cores"]
    conda:
        "epigenomics"
    threads:
        32
    shell:
        """
        samtools view -bS -F 0x04 {input} -@ {params.cores} -o {output.bam}
        samtools sort {output.bam} -@ {params.cores} -o {output.sorted_bam}
        samtools index {output.sorted_bam} -@ {params.cores}
        """

rule bam_to_bed:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/bam/{sample}_bowtie2.mapped.bam"
    output:
        bed="data/{assay}_{experiment}/{library}/{sample}/alignment/bed/{sample}_bowtie2.bed",
        clean_bed="data/{assay}_{experiment}/{library}/{sample}/alignment/bed/{sample}_bowtie2.clean.bed",
        fragments_bed="data/{assay}_{experiment}/{library}/{sample}/alignment/bed/{sample}_bowtie2.fragments.bed"
    params:
        cores=config["cores"]
    conda:
        "epigenomics"
    threads:
        32
    shell:
        """
        bedtools bamtobed -i {input} -bedpe > {output.bed}
        awk '$1==$4 && $6-$2 < 1000 {{print $0}}' {output.bed} > {output.clean_bed}
        cut -f 1,2,6 {output.clean_bed} | sort -k1,1 -k2,2n -k3,3n > {output.fragments_bed}
        """

rule make_bedgraph:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/bed/{sample}_bowtie2.fragments.bed"
    output:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/bedgraph/{sample}_bowtie2.fragments.bedgraph"
    params:
        chromSize=config["ChromSize"]
    conda:
        "epigenomics"
    shell:
        """
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/alignment/bedgraph
        bedtools genomecov -bg -i {input} -g {params.chromSize} > {output}
        """

rule bedgraph_to_bigwig:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/bedgraph/{sample}_bowtie2.fragments.bedgraph"
    output:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/bigwig/{sample}_bowtie2.bw"
    params:
        chromSize=config["ChromSize"],
        bgtobw="/mnt/WKD0P26R/UCSC_tools/bedGraphToBigWig"
    conda:
        "epigenomics"
    shell:
        """
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/alignment/bigwig
        {params.bgtobw} {input} {params.chromSize} {output}
        """

rule peak_calling:
    input:
        bedgraph="data/{assay}_{experiment}/{library}/{sample}/alignment/bedgraph/{sample}_bowtie2.fragments.bedgraph"
    output:
        peaks_final="data/{assay}_{experiment}/{library}/{sample}/peakCalling/SEACR/{sample}_seacr_top{seacr_cutoff}.peaks.stringent.bed"
    params:
        seacr="/home/luolab/GITHUB_REPOS/SEACR/SEACR_1.3.sh",
        out_prefix="data/{assay}_{experiment}/{library}/{sample}/peakCalling/SEACR/{sample}_seacr_top{seacr_cutoff}.peaks",
    conda:
        "epigenomics"
    shell:
        """
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/peakCalling/SEACR
        bash {params.seacr} {input.bedgraph} {wildcards.seacr_cutoff} non stringent {params.out_prefix}
        """

rule calculate_frip:
    input:
        bam="data/{assay}_{experiment}/{library}/{sample}/alignment/bam/{sample}_bowtie2.mapped.sorted.bam",
        idx="data/{assay}_{experiment}/{library}/{sample}/alignment/bam/{sample}_bowtie2.mapped.sorted.bam.bai",
        peaks="data/{assay}_{experiment}/{library}/{sample}/peakCalling/SEACR/{sample}_seacr_top{seacr_cutoff}.peaks.stringent.bed"
    output:
        "data/{assay}_{experiment}/{library}/{sample}/peakCalling/deeptools/{sample}_top{seacr_cutoff}_frip.txt"
    params:
        cores=config["cores"]
    conda:
        "epigenomics"
    threads:
        32
    shell:
        """
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/peakCalling/deeptools
        python scripts/calculate_frip.py --bam {input.bam} --peaks {input.peaks} --output {output} --cores {params.cores}
        """

rule generate_qc_report:
    input:
        "data/{assay}_{experiment}/{library}/{sample}/alignment/bam/{sample}_bowtie2.mapped.sorted.bam",
        "data/{assay}_{experiment}/{library}/{sample}/alignment/removeDuplicate/picard_summary/{sample}_picard.rmDup.txt",
        "data/{assay}_{experiment}/{library}/{sample}/alignment/sam/fragmentLen/{sample}_fragmentLen.txt",
        "data/{assay}_{experiment}/{library}/{sample}/peakCalling/deeptools/{sample}_top{seacr_cutoff}_frip.txt"
    output:
        html="data/{assay}_{experiment}/{library}/{sample}/report/{sample}_top{seacr_cutoff}_qc_report.html",
        json="data/{assay}_{experiment}/{library}/{sample}/report/{sample}_top{seacr_cutoff}_qc_metrics.json"
    params:
        assay="{assay}",
        experiment="{experiment}",
        library="{library}",
        sample="{sample}"
    conda:
        "epigenomics"
    shell:
        """
        echo "Creating directory: data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/report"
        mkdir -p data/{wildcards.assay}_{wildcards.experiment}/{wildcards.library}/{wildcards.sample}/report
        echo "Running R script with parameters: {wildcards.assay} {wildcards.experiment} {wildcards.library} {wildcards.sample} {wildcards.seacr_cutoff}"
        Rscript scripts/render_report.R {wildcards.assay} {wildcards.experiment} {wildcards.library} {wildcards.sample} {wildcards.seacr_cutoff}
        """

rule gather_qc_metrics:
    input:
        expand(
            "data/{assay}_{experiment}/{library}/{sample}/report/{sample}_top{seacr_cutoff}_qc_metrics.json",
            zip,
            assay=metadata.Assay.to_list(),
            experiment=metadata.ExperimentName.to_list(),
            library=metadata.LibraryName.to_list(),
            sample=metadata.SampleName.to_list(),
            seacr_cutoff=metadata.SeacrCutoff.to_list()
            )
    output:
        "reports/qc_summary_report.html"
    conda:
        "epigenomics"
    shell:
        """
        Rscript scripts/gather_qc_metrics.R {input}
        """



