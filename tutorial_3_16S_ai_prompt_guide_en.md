# Moving Pictures 16S: AI Agent Prompts & Results Interpretation Guide

This prompt library uses the repository's built-in 34 Moving Pictures single-end FASTQ files as the sole default dataset. Before submitting, Nano4 preflight must be used to validate user-specified project and partition.

## 1. One-Click Preparation & Submission

```text
Please use nano4-slurm-operations and slurm-ampliseq-guide to analyze the 34 Moving Pictures single-end FASTQ files built into the repository.

My Slurm project account is <PROJECT_ID>, and target partition is ngs250g.
Run read-only preflight first; if project, association, or partition policy is incompatible, stop and do not submit.

Please sequentially:
1. Confirm 01_data/fastq contains 34 L*.fastq.gz files.
2. Confirm samplesheet.template.tsv has sample, fastq_1 columns, with sample IDs matching metadata.tsv first column.
3. Execute 03_scripts/prepare_samplesheet.sh.
4. Execute 03_scripts/prepare_assets.sh on login node.
5. Validate submit_ampliseq.slurm uses --single_end, --trunclenf 120, and runs barplot & Adonis using body_site.
6. Submit using sbatch --account="<PROJECT_ID>", report Job ID, and monitor with non-polling mechanism.
```

## 2. Multi-Stage Prompts

### Input Data Validation

```text
Perform read-only check on Moving Pictures tutorial data: FASTQ must be exactly 34 files;
samplesheet.template.tsv must be single-end format; metadata must contain identical sample IDs
and body_site. Do not download or replace data.
```

### Assets & Submission (with `uv` Check)

```text
Check if `uv` is installed on the login node (if missing, install via `curl -LsSf https://astral.sh/uv/install.sh | sh` and run `source ~/.bashrc` to load PATH).

Run 03_scripts/prepare_assets.sh on the login node. Assets must be stored under the current account's own `/work/${USER}/` directories; do not use another account's cache.

After assets are ready, run Nano4 preflight with my project <PROJECT_ID> and ngs250g. Upon passing, submit 03_scripts/submit_ampliseq.slurm using Moving Pictures single-end parameters and report Job ID.
```

## 3. Post-Analysis Q&A

### QC & DADA2

```text
Read MultiQC and DADA2 stats, summarizing read retention rate, abnormally low depth samples,
and final ASV count for the 34 Moving Pictures samples. Quote actual output numbers instead of template values.
```

### Alpha / Beta Diversity

```text
Compare Alpha diversity across gut, tongue, left palm, right palm by body_site,
and extract R², p-value, and limitations from actual Adonis/PERMANOVA outputs.
```

### Taxonomy

```text
Read ASV_table.tsv and ASV_tax.silva_138_2.tsv, summarizing top phyla and genera across different body_sites;
distinguish between results directly supported by data vs biological inferences.
```

### Charts & Reports

```text
Run 03_scripts/phyloseq_analysis.R to plot relative abundance and Bray-Curtis PCoA by body_site,
saving a comprehensive report based on actual results to 04_viewer/report.md.
```
