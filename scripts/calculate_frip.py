import argparse
import pysam
import deeptools.countReadsPerBin as crpb

def calculate_frip(bam_file, bed_file, output_file, cores):
    # Number of reads per bin
    cr = crpb.CountReadsPerBin([bam_file], bedFile=[bed_file], numberOfProcessors=cores)
    reads_at_peaks = cr.run()

    # Total number of reads per peaks per bam
    total = reads_at_peaks.sum(axis=0)

    bam = pysam.AlignmentFile(bam_file, "rb")
    
    frip = total / bam.mapped
    
    with open(output_file, "w") as f:
        f.write(f"FRiP score: {frip}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate FRiP score")
    parser.add_argument("--bam", required=True, help="Input BAM file")
    parser.add_argument("--peaks", required=True, help="Input peaks BED file")
    parser.add_argument("--output", required=True, help="Output file for FRiP score")
    parser.add_argument("--cores", type=int, default=1, help="Number of cores to use")
    
    args = parser.parse_args()
    calculate_frip(args.bam, args.peaks, args.output, args.cores)