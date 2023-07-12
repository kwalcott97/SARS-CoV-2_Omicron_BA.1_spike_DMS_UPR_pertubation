"""``snakemake`` files with rules for calculating functional effects."""


# read the config for func effects
with open(config["func_effects_config"]) as f:
    func_effects_config = yaml.safe_load(f)

# get configuration for functional scores and make sure all samples defined
func_scores = func_effects_config["func_scores"]
for selection_name, selection_d in func_scores.items():
    for s in ["post_selection_sample", "pre_selection_sample"]:
        if selection_d[s] not in sample_to_library:
            raise ValueError(
                f"{s} for {selection_name} of {selection_d[s]} not in barcode_runs"
            )

# Names and values of files to add to docs
func_effects_docs = collections.defaultdict(dict)


rule func_scores:
    """Compute functional scores for variants."""
    input:
        unpack(
            lambda wc: {
                s: f"results/barcode_counts/{func_scores[wc.selection][s]}_counts.csv"
                for s in ["post_selection_sample", "pre_selection_sample"]
            }
        ),
        codon_variants=config["codon_variants"],
        gene_sequence_codon=config["gene_sequence_codon"],
        site_numbering_map=config["site_numbering_map"],
    output:
        func_scores="results/func_scores/{selection}_func_scores.csv",
        count_summary="results/func_scores/{selection}_count_summary.csv",
    params:
        func_score_params=lambda wc: func_scores[wc.selection]["func_score_params"],
        samples=lambda wc: {
            s: func_scores[wc.selection][s]
            for s in ["post_selection_sample", "pre_selection_sample"]
        },
        dates=lambda wc: {
            s: sample_to_date[func_scores[wc.selection][s]]
            for s in ["post_selection_sample", "pre_selection_sample"]
        },
        # script will throw error if pre_library and post_library differ
        libraries=lambda wc: {
            s: sample_to_library[func_scores[wc.selection][s]]
            for s in ["post_selection_sample", "pre_selection_sample"]
        },
    conda:
        "environment.yml"
    log:
        "results/logs/func_scores_{selection}.txt",
    script:
        "scripts/func_scores.py"


for s in func_scores:
    func_effects_docs["Per-variant functional scores"][
        s
    ] = f"results/func_scores/{s}_func_scores.csv"


rule analyze_func_scores:
    """Analyze functional scores."""
    input:
        func_scores=expand(rules.func_scores.output.func_scores, selection=func_scores),
        count_summaries=expand(
            rules.func_scores.output.count_summary,
            selection=func_scores,
        ),
        nb=os.path.join(
            config["pipeline_path"],
            "notebooks/analyze_func_scores.ipynb",
        ),
    output:
        nb="results/notebooks/analyze_func_scores.ipynb",
    conda:
        "environment.yml"
    log:
        "results/logs/analyze_func_scores.txt",
    shell:
        "papermill {input.nb} {output.nb} &> {log}"


func_effects_docs["Analysis of functional scores"] = rules.analyze_func_scores.output.nb


rule func_effects_global_epistasis:
    """Fit global epistasis model to func scores to get mutation functional effects."""
    input:
        func_scores="results/func_scores/{selection}_func_scores.csv",
        nb=os.path.join(
            config["pipeline_path"],
            "notebooks/func_effects_global_epistasis.ipynb",
        ),
    output:
        func_effects="results/func_effects/by_selection/{selection}_func_effects.csv",
        nb="results/notebooks/func_effects_global_epistasis_{selection}.ipynb",
    params:
        global_epistasis_params_yaml=lambda wc: yaml.dump(
            {
                "global_epistasis_params": func_scores[wc.selection][
                "global_epistasis_params"
                ],
            }
        ),
    threads: 1
    conda:
        "environment.yml"
    log:
        "results/logs/func_effects_global_epistasis_{selection}.txt",
    shell:
        """
        papermill {input.nb} {output.nb} \
            -p selection {wildcards.selection} \
            -p func_scores {input.func_scores} \
            -p func_effects {output.func_effects} \
            -p threads {threads} \
            -y "{params.global_epistasis_params_yaml}" \
            &> {log}
        """


for s in func_scores:
    func_effects_docs["Per-selection global epistasis fitting"][
        s
    ] = f"results/notebooks/func_effects_global_epistasis_{s}.ipynb"
    func_effects_docs["Per-selection mutation functional effects"][
        s
    ] = f"results/func_effects/by_selection/{s}_func_effects.csv"


rule avg_func_effects:
    """Average and plot the functional effects for a condition."""
    input:
        site_numbering_map_csv=config["site_numbering_map"],
        selections=lambda wc: [
            f"results/func_effects/by_selection/{s}_func_effects.csv"
            for s in func_effects_config["avg_func_effects"][wc.condition][
                "selections"
            ]
        ],
        nb=os.path.join(config["pipeline_path"], "notebooks/avg_func_effects.ipynb"),
    output:
        nb="results/notebooks/avg_func_effects_{condition}.ipynb",
        func_effects_csv="results/func_effects/averages/{condition}_func_effects.csv",
        functional_html="results/func_effects/averages/{condition}_func_effects_nolegend.html",
        latent_html="results/func_effects/averages/{condition}_latent_effects_nolegend.html",
    params:
        params_yaml=lambda wc: yaml.dump(
            {"params": func_effects_config["avg_func_effects"][wc.condition]}
        ),
    conda:
        "environment.yml"
    log:
        "results/logs/avg_func_effects_{condition}.txt",
    shell:
        """
        papermill {input.nb} {output.nb} \
            -p site_numbering_map_csv {input.site_numbering_map_csv} \
            -p func_effects_csv {output.func_effects_csv} \
            -p functional_html {output.functional_html} \
            -p latent_html {output.latent_html} \
            -y '{params.params_yaml}' \
            &> {log}
        """


func_effects_docs["Notebooks averaging mutation functional effects for conditions"] = {
    c: f"results/notebooks/avg_func_effects_{c}.ipynb"
    for c in func_effects_config["avg_func_effects"]
}

func_effects_docs["Average mutation functional effects for each condition"] = {
    c: f"results/func_effects/averages/{c}_func_effects.csv"
    for c in func_effects_config["avg_func_effects"]
}

docs["Functional effects of mutations"] = func_effects_docs
