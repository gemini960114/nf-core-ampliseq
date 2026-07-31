# 🚀 HPC Slurm AI Agent Quickstart & Prompt Guide
> **HPC & Slurm AI-Assisted Bio-Analysis Quickstart Guide**

This guide provides natural language prompts suitable for NCHC / Slurm HPC environments. You can copy the prompts below directly and send them to the AI Agent to automatically query HPC resources, verify project authorization, and submit bioinformatics analysis jobs.

> The 1,000-read synthetic FASTQ practice in this chapter is an independent Slurm exercise using only `data/` and `script/`; it will not modify the 34 Moving Pictures main dataset in `01_data/`.

---

## 📋 Quick Navigation Checklist

| Stage | Step | Task Goal | Core Tools / Commands |
| :--- | :--- | :--- | :--- |
| **1. Environment & Resource Query** | **Prompt 1** | Query available Slurm Partition resources & hardware limits | `sinfo` / `scontrol` |
| | **Prompt 2** | Use `wallet` command to list available project IDs & quotas | `wallet` |
| | **Prompt 3** | Verify specific project ID (`GOV115088`) & NGS partition permissions | `wallet` / `sacctmgr` / `scontrol` |
| **2. Bio-Analysis Job Submission** | **Prompt 4** | Auto-generate test data, write Python QC script & submit Slurm Job | `sbatch` / Python / `ngs62g` |

---

## 💬 Standalone Prompt Library

### 📌 Prompt 1: Query Slurm Partition Resources
> **Purpose**: Allows the AI Agent to automatically inspect all submit-able partitions, node statuses, and CPU/memory limits on the HPC.

```text
Please check and list all Slurm Partition resources available to me on this HPC.
Use `sinfo` or relevant commands to summarize each Partition's name, node count, state (e.g. idle/alloc), CPU core counts, and memory limits.
```

---

### 📌 Prompt 2: Query Project Codes Using Wallet Command
> **Purpose**: Allows the AI Agent to automatically query all NCHC HPC project IDs (Project ID / Account) and point balances registered under your account.

```text
Please run the `wallet` command to list all HPC project IDs (Project ID / Account) assigned to me, and summarize the available balance and status for each project.
```

---

### 📌 Prompt 3: Verify Specific Project Code (GOV115088)
> **Purpose**: Verifies whether a specified project code exists and is valid, checking its submission permissions across NGS Partitions (`ngs8g`/`ngs16g`/`ngs32g`/`ngs62g`/`ngs125g`).

```text
Please use the nano4-slurm-operations skill to confirm which of the following Partitions project GOV115088 can use:
`ngs8g` / `ngs16g` / `ngs32g` / `ngs62g` / `ngs125g`
Please confirm whether `GOV115088` has a Slurm association, and inspect each Partition's AllowAccounts / DenyAccounts (Note: Currently only `ngs62g` is available; `ngs8g` etc. are unavailable). As this biomedical project may not appear in standard Nano4 wallet listings, check partition policies simultaneously rather than relying solely on wallet output.
```

---

### 📌 Prompt 4: Bioinformatics FASTQ QC Analysis & Slurm Job Submission
> **Purpose**: Fully automated! The AI automatically generates a 1,000-read test FASTQ file, writes a Python script for GC% and read-length statistics, composes a Slurm submission script, and submits it to the `ngs62g` partition.

```text
Please assist in creating and submitting a FASTQ bio-analysis job:
1. Automatically generate a test FASTQ file `data/test_sample.fastq` containing 1,000 reads under `data/` (if FASTQ files already exist in the project, use existing files).
2. Create a Python script `script/fastq_qc_stats.py` under `script/` to read the FASTQ file and calculate total read count, average read length, and GC content %.
3. Compose a Slurm submission script under `script/` with partition set to `ngs62g`, logging to `logs/`; do not hardcode the project account in version-controlled scripts.
4. Run nano4-slurm-operations preflight first, then submit the job using `sbatch --account="GOV115088"`, reporting the Job ID and output inspection steps.
```

---

## 💡 Best Practices for AI Agents on HPC

1. **Pre-create Log Directories**: Slurm requires `--output` and `--error` log paths before job launch; ensure `logs/` folder exists beforehand.
2. **Pass Project Code Correctly**: Do not hardcode account IDs in tracked scripts; pass `sbatch --account="<PROJECT_ID>" ...` at submission time.
3. **Non-Polling Monitoring**: After submitting jobs, query status using single commands like `squeue -j <JOB_ID>` instead of infinite background `sleep` loops.
