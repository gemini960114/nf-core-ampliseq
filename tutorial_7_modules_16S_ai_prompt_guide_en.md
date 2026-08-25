# Moving Pictures 16S: HPC System Modules AI Agent Prompt & Interpretation Guide

This prompt library is specifically optimized for NCHC Nano4 **system environment modules (`biology/qiime2/2026.7` and `biology/nf-core-ampliseq/2.18.0`)**. By loading pre-packaged site offline modules, the AI Agent can bypass manual asset downloads and directly execute Moving Pictures 16S single-end analysis on Slurm HPC along with interactive QIIME 2 command-line interpretation.

---

## 1. One-Click Preparation & Submission Prompt

```text
Please use nano4-slurm-operations and slurm-ampliseq-guide to analyze the built-in 34 Moving Pictures single-end FASTQ files on Nano4 using system official modules biology/qiime2/2026.7 and biology/nf-core-ampliseq/2.18.0.

My Slurm project account is <PROJECT_ID>, and target partition is ngs62g.
Run read-only preflight first; if project, association, or partition policy is incompatible, stop and do not submit.

Please sequentially:
1. Confirm 01_data/fastq contains 34 L*.fastq.gz files.
2. Execute 03_scripts/prepare_samplesheet.sh to generate samplesheet.tsv with absolute paths.
3. Load system modules module purge && ml biology/qiime2/2026.7 biology/nf-core-ampliseq/2.18.0, and verify $NFCORE_AMPLISEQ_HOME and $NFCORE_SITE_CONFIG environment variables.
4. Validate 03_scripts/submit_ampliseq_module.slurm uses --single_end, --trunclenf 120, and references $NFCORE_SITE_CONFIG.
5. Submit using sbatch --account="<PROJECT_ID>" 03_scripts/submit_ampliseq_module.slurm, report Job ID, and monitor using non-polling timers until completion.
6. Upon completion, report the MultiQC summary path (results/multiqc/multiqc_report.html).
```

---

## 2. Multi-Stage Prompts

### Input Data & System Module Validation

```text
Please check current Nano4 system modules environment:
1. Run module avail to verify biology/qiime2/2026.7 and biology/nf-core-ampliseq/2.18.0 are available.
2. Perform read-only check on 01_data/: confirm FASTQ count is 34 single-end files, samplesheet.template.tsv columns are valid, and metadata.tsv contains sampleID and body_site.
3. Do not run asset download scripts; verify site offline package environment paths directly.
```

### Module Job Submission & Preflight

```text
Load system modules: ml biology/qiime2/2026.7 biology/nf-core-ampliseq/2.18.0.

Run Nano4 Slurm preflight using my project account <PROJECT_ID> and partition ngs62g. Upon passing, submit 03_scripts/submit_ampliseq_module.slurm via sbatch --account="<PROJECT_ID>", report Job ID, and configure non-polling completion notification.
```

### Interactive Analysis with System QIIME 2 Module (No Container Wrapper Needed)

```text
Once pipeline completes, load module ml biology/qiime2/2026.7 directly in terminal:
1. Use qiime tools peek to inspect DADA2 FeatureTable (.qza) metadata under results/qiime2/.
2. Run qiime metadata tabulate to generate metadata visualization results/qiime2/metadata.qzv.
3. Summarize key taxonomy profiles and alpha/beta diversity metrics for the user.
```

---

## 3. Post-Analysis Q&A & Interpretation

### QC & DADA2 Read Retention Rates

```text
Read MultiQC and DADA2 stats (results/dada2/DADA2_stats.tsv), summarizing read retention rates across Input, Filtered, Denoised, and Non-chimeric stages, along with final ASV counts for the 34 Moving Pictures samples. Quote actual output numbers.
```

### Alpha / Beta Diversity & Adonis Statistics

```text
Read results under results/qiime2/diversity/, comparing Alpha diversity (Shannon / Faith PD) by body_site (gut, tongue, left palm, right palm), and extracting R², p-values, and significance interpretations from Adonis/PERMANOVA outputs.
```

### Data Summary & Report Generation

```text
Read results under results/, generate the overall summary table at results/overall_summary.tsv, and write a structured analysis report to 04_viewer/report.md. Provide instructions on opening the 04_viewer/index.html web dashboard.
```
