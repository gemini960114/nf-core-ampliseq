---
name: slurm_ampliseq_guide
description: Prepare and run nf-core/ampliseq 16S microbiome workflows using Singularity and Nextflow, including container caching, metadata validation, samplesheet generation, taxonomy references, pipeline parameters, and result handling. Use for ampliseq data preparation or execution; on Nano4, also use nano4-slurm-operations for wallet, account, partition, submission, and monitoring.
---

# Slurm HPC Automation Guide for nf-core/ampliseq

On Nano4, run the `nano4-slurm-operations` preflight before any submission. Keep
site-wide wallet, account, partition, GPU, and Slurm lifecycle rules in that skill;
this skill owns only ampliseq-specific workflow rules.

When the user asks to run `nf-core/ampliseq` on Slurm HPC nodes or prepare 16S amplicon data, follow this exact workflow:

## 1. Directory Structure & Metadata Validation Rules
- Standard directory layout:
  - `01_data/`: Contains `samplesheet.template.tsv`, generated `samplesheet.tsv`, `metadata.tsv`, and `fastq/` files.
  - `02_config/`: Contains Nextflow and Singularity configuration.
  - `03_scripts/`: Contains Slurm submission scripts (`submit_ampliseq.slurm`) and AI prompt examples.
- Ensure the version-controlled `logs/` directory exists before calling `sbatch`, because Slurm opens `--output` and `--error` before the batch script body runs.
- Run `bash 03_scripts/prepare_samplesheet.sh` after cloning and before job submission. It MUST generate `samplesheet.tsv` from the version-controlled `samplesheet.template.tsv` using the current clone's absolute path.
- Generated `samplesheet.tsv`: Tab-separated. Column 1 must be `sample`. `fastq_1` (and `fastq_2` if paired-end) MUST point to existing, valid absolute paths to `.fastq.gz` files (verify symlinks exist before job submission). Do not commit this generated file.
- `metadata.tsv`: Column 1 header MUST be `sampleID` or `sample-id`. Column names used in downstream QIIME 2 / Adonis analyses MUST replace hyphens `-` with underscores `_` (e.g., `body_site`).

## 2. HPC Environment & Container Setup
- Always load NCHC official modules:
  ```bash
  module purge
  module load biology/Nextflow/26.04.6 singularity/4.3.7
  ```
- Always use the current user's private Singularity cache directory. Never use another account's cache:
  ```bash
  export NXF_SINGULARITY_CACHEDIR="/work/${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3"
  mkdir -p "$NXF_SINGULARITY_CACHEDIR"
  ```
- Before submission, run `bash 03_scripts/prepare_assets.sh` on the login node. It pins nf-core/tools 4.0.3 with `uv tool run --from nf-core==4.0.3`, fetches nf-core/ampliseq 2.18.0 and all Singularity images without `--force`, and downloads SILVA 138.2 into the current user's `/work/${USER}/reference_databases/` directory.
- Keep the nf-core/tools version and versioned cache path synchronized in `prepare_assets.sh`, `setup_environment.sh`, and `submit_ampliseq.slurm`. Reuse valid legacy `.img` files through symbolic links rather than copying or downloading identical image contents.
- **ALWAYS verify that the version-controlled `nextflow.config` exists in the project root and contains the following settings** before running the pipeline. Repair it if missing or incorrect:
  ```groovy
  /*
   * Nextflow configuration for nf-core/ampliseq on NCHC Slurm HPC
   */

  singularity {
      enabled     = true
      autoMounts  = true
      runOptions  = '-B /tmp:/tmp'  // Fix: QIIME 2 (2026.7+) Python 3.12 rachis temp isolation
  }

  process {
      executor = 'local'  // Fix: prevents Nextflow from re-submitting sbatch (No project ID error)
      beforeScript = '''
          mkdir -p "$PWD/.nxf-tmp"
          export TMPDIR="$PWD/.nxf-tmp"
          export TMP="$TMPDIR"
          export TEMP="$TMPDIR"
      '''.stripIndent().trim()
  }
  ```
  > Reason: (1) `-B /tmp:/tmp` prevents QIIME 2 Python 3.12 container temp file isolation failures. (2) `executor = 'local'` ensures Nextflow tasks run inside the allocated ngs250g node, not re-submitted via sbatch which causes `No project ID was assigned` error on NCHC.


## 3. Ampliseq Resource Allocation
- Use `ngs250g` with 32 CPUs and 250G RAM as this repository's default full
  analysis profile.
- Validate the live account/partition compatibility and limits with
  `nano4-slurm-operations`; do not maintain a duplicate site partition list here.
- Honor explicit user CPU/memory requests only when they fit the selected
  partition and workflow.
- **Flexible Pipeline Arguments**:
  - Pipeline source: Use `${AMPLISEQ_PIPELINE:-/work/${USER}/nf-core_download/ampliseq-2.18.0/2_18_0}`. Never hard-code a path under another user's `/work/<account>/` directory.
  - Use `--ref_taxonomy_storage "/work/${USER}/reference_databases/ampliseq/silva-138.2"` for the default SILVA database.
  - Never defer Pipeline, container image, or reference database downloads to a compute node.
  - Reference taxonomy: `--dada_ref_taxonomy "silva=138.2"` (default for 16S), or `"unite-fungi=9.0"` (for ITS), `"pr2=5.0.0"` (for 18S).
  - Sequence type: If single-end, add `--single_end --trunclenf 120`. If paired-end, remove `--single_end` and set `--trunclenf` & `--trunclenr`.
  - Flags: `--skip_cutadapt` (if demultiplexed and primers cut), `--skip_phyloseq` (to avoid online R package download timeouts).

## 4. Agent Non-Polling Monitoring Pattern
- Delegate Nano4 account validation, submission, monitoring, and cancellation to
  `nano4-slurm-operations`.
- Report the job ID and workflow-specific output locations after submission.
- Use `-resume` after diagnosing a failed run; never remove the Nextflow work
  directory merely to retry.
