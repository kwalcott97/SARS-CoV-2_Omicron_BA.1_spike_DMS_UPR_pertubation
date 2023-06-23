# Input data
This subdirectory contains input data used by the pipeline.

## PacBio full-length variant sequencing to link barcodes

[PacBio_amplicon.gb](PacBio_amplicon.gb): Genbank file having features to parse with [alignparse](https://jbloomlab.github.io/alignparse/). Must have *gene* (the gene of interest) and *barcode* features.

[PacBio_feature_parse_specs.yaml](PacBio_feature_parse_specs.yaml): How to parse the PacBio amplicon using [alignparse](https://jbloomlab.github.io/alignparse/).

[PacBio_runs.csv](PacBio_runs.csv): List of PacBio CCS FASTQs used to link barcodes to variants.
It must have the following columns:

 - `library`: name of the library
 - `run`: name of the sequencing run, must be unique
 - `fastq`: FASTQ file from running CCS

## Site numbering
[site_numbering_map.csv](site_numbering_map.csv): Maps sequential 1, 2, ... numbering of the gene to a "reference" numbering scheme that represents the standard naming of sites for this gene.
Also assigns each site to a region (domain) of the protein.
So must have columns *sequential_site*, *reference_site*, and *region*.

## Mutation-type classification
[data/mutation_design_classification.csv](data/mutation_design_classification.csv) classifies mutations into the different categories of designed mutations.
Should have columns *sequential_site*, *amino_acid*, and *mutation_type*.

## Neutralization standard barcodes
[neutralization_standard_barcodes.csv](neutralization_standard_barcodes.csv) barcodes for the neutralization standards.
Must have columns *barcode* and *name*, giving the barcode and name of this neutralization standard set.