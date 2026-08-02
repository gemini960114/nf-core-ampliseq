# 16S Amplicon Analysis: Moving Pictures Manual Guide

This tutorial uses the repository's built-in 34 Moving Pictures single-end FASTQ files, running on Nano4 with nf-core/ampliseq 2.18.0, Nextflow, and Singularity.

## 1. Clone & Input Validation

```bash
cd "/work/$USER"
git clone https://github.com/gemini960114/nf-core-ampliseq.git
cd nf-core-ampliseq

find 01_data/fastq -maxdepth 1 -name '*.fastq.gz' | wc -l
bash 03_scripts/prepare_samplesheet.sh
head -3 01_data/samplesheet.tsv
head -1 01_data/metadata.tsv
```

The expected FASTQ count is 34; samplesheet columns are `sample`, `fastq_1`; metadata's first column is `sampleID`, containing `body_site`.

## 2. Prepare Assets on Login Node

### 2.1 Check Prerequisites & Install `uv`
`prepare_assets.sh` requires `uv` (used to pin `nf-core==4.0.3`). If `uv` is not installed on your account, run the following on the login node:
> **Note**: The official installer places `uv` under `~/.local/bin/uv` and writes PATH to `~/.bashrc`. Run `source ~/.bashrc` (or add `export PATH="$HOME/.local/bin:$PATH"`) after installation to ensure your current shell recognizes the `uv` command.

```bash
# If uv is not installed, run:
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

### 2.2 Prepare Assets

Each user should run the preparation script on the login node. Assets are stored under the current account's own `/work/${USER}/` directories.

```bash
module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7

export NXF_SINGULARITY_CACHEDIR="/work/${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3"
bash 03_scripts/prepare_assets.sh
```

`prepare_assets.sh` pre-packages or verifies ampliseq 2.18.0, Singularity images, and SILVA 138.2. Do not download these assets on compute nodes.

## 3. Validate Settings & Slurm Permissions

Replace `<PROJECT_ID>` with your authorized project code. `GOV115088` is restricted to users with biomedical allocation access using allowed `ngs*` partitions.

```bash
bash -n 03_scripts/submit_ampliseq.slurm

bash .agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh \
  --project "<PROJECT_ID>" \
  --partition "ngs250g"
```

Proceed to submission only if preflight passes completely. Moving Pictures submission parameters are:

- `--single_end`
- `--trunclenf 120`
- `--metadata_category_barplot "body_site"`
- `--qiime_adonis_formula "body_site"`

## 4. Submit & Check Status

```bash
mkdir -p logs
sbatch --account="<PROJECT_ID>" 03_scripts/submit_ampliseq.slurm
squeue -u "$USER"
```

After obtaining the Job ID, use a single query command to check status; do not construct infinite polling loops:

```bash
sacct -j "<JOB_ID>" --format=JobID,State,ExitCode,Elapsed
```

## 5. Results

Upon successful completion, primary outputs include:

- `results/multiqc/multiqc_report.html`
- `results/dada2/ASV_table.tsv`
- `results/dada2/ASV_tax.silva_138_2.tsv`
- `results/qiime2/`

To launch the integrated web viewer, start from the project root on the login node:

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory .
```

Then open `http://localhost:8000/04_viewer/index.html` via SSH port forwarding.
