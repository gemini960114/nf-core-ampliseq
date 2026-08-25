# 16S Amplicon Analysis: HPC Environment Modules Manual Guide

This tutorial utilizes official pre-built HPC system modules on NCHC Nano4—**`biology/qiime2/2026.7`** and **`biology/nf-core-ampliseq/2.18.0`**—along with the repository's built-in 34 Moving Pictures single-end FASTQ datasets. Nextflow and Singularity run the 16S amplicon workflow, followed by direct interactive QIIME 2 command line analysis.

Unlike Tutorial 2 (which relies on manually prepared asset downloads under `/work/${USER}/`), this guide directly uses site-maintained offline modules, bypassing asset download scripts for faster, streamlined execution.

---

## 1. Introduction & Advantages of System Modules

On Nano4 HPC, environment modules can be loaded directly using `ml` (or `module load`):

```bash
module purge
ml biology/qiime2/2026.7
ml biology/nf-core-ampliseq/2.18.0
```

Loading these modules configures key environment variables and utilities:

1. **`biology/nf-core-ampliseq/2.18.0`**:
   - Automatically loads `biology/Nextflow/26.04.6` and `biology/nfcore_config`.
   - Sets `$NFCORE_AMPLISEQ_HOME` pointing to pre-packaged offline pipeline code:
     (`/work/envstack/apps/application/biology/nf-core/pipelines/ampliseq/2.18.0/2_18_0`).
   - Sets `$NFCORE_SITE_CONFIG` and `$NFCORE_SITE_REFERENCES` for site-wide optimizations.
   - Provides `nfcore-submit` helper tool.
2. **`biology/qiime2/2026.7`**:
   - Provides pre-installed QIIME 2 2026.7 Conda environment (including classifier path `$QIIME2_CLASSIFIER_ROOT`).
   - Enables direct execution of `qiime` command-line tools without container wrapping.
   - Provides submission utilities `qiime2-submit` and `qiime2-parallel-submit`.

---

## 2. Clone & Input Validation

Switch to your `/work/$USER` directory and clone the repository:

```bash
cd "/work/$USER"
git clone https://github.com/gemini960114/nf-core-ampliseq.git
cd nf-core-ampliseq

# Validate FASTQ file count (expected: 34 single-end FASTQs)
find 01_data/fastq -maxdepth 1 -name '*.fastq.gz' | wc -l

# Regenerate samplesheet.tsv with absolute paths for the current clone
bash 03_scripts/prepare_samplesheet.sh

# Inspect samplesheet and metadata headers
head -3 01_data/samplesheet.tsv
head -1 01_data/metadata.tsv
```

The expected FASTQ count is 34; `samplesheet.tsv` contains `sample` and `fastq_1`; `metadata.tsv` first column header is `sampleID`, containing `body_site`.

---

## 3. Validate Settings & Slurm Permissions

Replace `<PROJECT_ID>` with your authorized project code (e.g., `GOV115088` or general project ID).

Run syntax validation and Nano4 preflight checks before job submission:

```bash
bash -n 03_scripts/submit_ampliseq_module.slurm

bash .agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh \
  --project "<PROJECT_ID>" \
  --partition "ngs62g"
```

Proceed to submission only if preflight passes completely. Key parameters configured in [03_scripts/submit_ampliseq_module.slurm](file:///work/c00cjz00/nf-core-ampliseq/03_scripts/submit_ampliseq_module.slurm) are:

- `-c "$NFCORE_SITE_CONFIG"`: Loads site-wide dynamic Slurm partition selector
- `--single_end`
- `--trunclenf 120`
- `--metadata_category_barplot "body_site"`
- `--qiime_adonis_formula "body_site"`

---

## 4. Submit & Check Status

Ensure the log directory `logs/` exists before submission:

```bash
mkdir -p logs
sbatch --account="<PROJECT_ID>" 03_scripts/submit_ampliseq_module.slurm
squeue -u "$USER"
```

After obtaining the Job ID, use a single query command to check status; do not construct infinite polling loops:

```bash
sacct -j "<JOB_ID>" --format=JobID,State,ExitCode,Elapsed
```

---

## 5. Downstream Analysis with System `biology/qiime2/2026.7` Module

Once the pipeline finishes, you can directly run `qiime` commands in your terminal without manual container wrapper setup:

```bash
# Load QIIME 2 environment module
ml biology/qiime2/2026.7

# Peek at the DADA2 FeatureTable artefact info
qiime tools peek results/qiime2/dada2_table.qza

# Generate Metadata visualization (.qzv)
qiime metadata tabulate \
  --m-input-file 01_data/metadata.tsv \
  --o-visualization results/qiime2/metadata.qzv
```

---

## 6. Results & Web Visualization Dashboard

Upon successful completion, primary outputs include:

- **MultiQC Summary Report**: `results/multiqc/multiqc_report.html`
- **DADA2 ASV Matrix & Taxonomy**: `results/dada2/ASV_table.tsv` and `results/dada2/ASV_tax.silva_138_2.tsv`
- **QIIME 2 Visualizations**: `results/qiime2/barplot/index.html` and `results/qiime2/diversity/`
- **Overall Sequence Filtering Summary**: `results/overall_summary.tsv`

### Integrated HTML Web Dashboard

Start the background HTTP server on the login node from the repository root:

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory .
```

Set up SSH port forwarding on your local machine:

```bash
ssh -L 8000:localhost:8000 <ACCOUNT>@<HPC_LOGIN_HOST>
```

Open `http://localhost:8000/04_viewer/index.html` in your web browser to seamlessly view MultiQC reports, QIIME 2 barplots, Alpha rarefaction curves, and 3D Beta PCoA plots.
