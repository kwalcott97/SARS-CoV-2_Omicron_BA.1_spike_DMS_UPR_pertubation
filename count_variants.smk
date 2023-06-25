"""``snakemake`` files with rules for counting variants from barcode sequencing."""


# Names and values of files to add to docs
count_variants_docs = collections.defaultdict(dict)


rule count_barcodes:
    """Count barcodes for each sample."""
    input:
        fastq_R1=lambda wc: barcode_runs.set_index("sample").at[wc.sample, "fastq_R1"],
        variants=config["codon_variants"],
    output:
        counts="results/barcode_counts/{sample}_counts.csv",
        counts_invalid="results/barcode_counts/{sample}_invalid.csv",
        fates="results/barcode_counts/{sample}_fates.csv",
    params:
        parser_params=config["illumina_barcode_parser_params"],
        library=lambda wc: barcode_runs.set_index("sample").at[wc.sample, "library"],
    conda:
        "environment.yml"
    log:
        "results/logs/count_barcodes_{sample}.txt",
    script:
        "scripts/count_barcodes.py"


for sample in barcode_runs["sample"]:
    count_variants_docs["Barcode counts"][sample] = os.path.join(
        "results/barcode_counts",
        f"{sample}_counts.csv",
    )


docs["Count variants"] = count_variants_docs
