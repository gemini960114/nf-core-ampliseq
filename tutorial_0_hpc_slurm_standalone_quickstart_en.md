# 🚀 HPC Slurm AI Agent Zero-Threshold Quickstart Guide (No Git Clone Required)
> **HPC & Slurm Standalone AI-Assisted Quickstart Guide (No Repo / No Skill Required)**

This guide provides **universal AI Agent prompts** suitable for NCHC / Slurm HPC environments.
**No `git clone` of this repository is required, nor is installing any custom Agent Skill**. You can directly copy the prompts below and send them to any AI Agent with Terminal execution privileges (e.g., ChatGPT, Claude, Cursor, Antigravity, etc.) to automatically complete HPC resource queries, project authorization validation, and bioinformatics analysis job submissions, producing structured Markdown report files.

---

## 🧪 Zero-Preparation Execution Workflow

Users do not need to download or clone any project files in advance. Simply log in to the HPC and type in your terminal:

```bash
# Create a blank test directory and navigate into it
mkdir -p ~/slurm_quickstart_test && cd ~/slurm_quickstart_test
```

Then sequentially copy **Prompt 1 through Prompt 4** from this guide and send them to the AI Agent. The AI will automatically handle everything from resource inventory, writing test files, to submitting Slurm jobs, generating 4 result documents (`partition.md`, `project.md`, `permission.md`, `report.md`)!

---

## 📋 Quick Navigation Checklist

| Stage | Step | Task Goal | Native Commands | Output File |
| :--- | :--- | :--- | :--- | :--- |
| **1. Environment & Resource Query** | **Prompt 1** | Query available Slurm Partition resources & hardware limits | `sinfo` / `scontrol` | `partition.md` |
| | **Prompt 2** | Use `wallet` command to list available project IDs & quotas | `wallet` | `project.md` |
| | **Prompt 3** | Verify specific project ID (`GOV115088`) & NGS partition permissions | `sacctmgr` / `scontrol` | `permission.md` |
| **2. Bio-Analysis Job Submission** | **Prompt 4** | Auto-generate test data, write Python QC script & submit Slurm Job | `sbatch` / Python / `ngs62g` | `report.md` |

---

## 💬 Standalone Universal Prompt Library

### 📌 Prompt 1: Query Slurm Partition Resources

```text
Please check and list all Slurm Partition resources available to me on this HPC.
Use `sinfo` along with `scontrol show partition` commands to summarize each Partition's name, node count, state (e.g. UP/DOWN, idle/alloc), CPU cores, memory limits, and maximum run time (MaxTime).
Output the result to partition.md
```

#### 📖 Explanation & Mechanics:
* **Purpose**: Allows the AI Agent to automatically inventory all partition resources, hardware limits, and node statuses on the HPC cluster.
* **No-Skill Mechanism**: `sinfo` and `scontrol` are native CLI tools of the Slurm workload manager, pre-installed on any Linux login node without requiring extra skills.
* **Key Advantages**: Requesting the AI Agent to combine `scontrol show partition` avoids missing time limits or detailed AllowAccounts / DenyAccounts restrictions, automatically saving findings to `partition.md`.

---

### 📌 Prompt 2: Query Project IDs Using Wallet

```text
Please run the `wallet` command to list all HPC project IDs (Project ID / Account) assigned to me, and summarize the available balance and status for each project.
Output the result to project.md
```

#### 📖 Explanation & Mechanics:
* **Purpose**: Queries all project IDs (Accounts) registered under the user's account in the HPC system along with remaining SU (Service Units) balance.
* **No-Skill Mechanism**: `wallet` is NCHC HPC's native point query utility (located at `/usr/bin/wallet`), executable as long as the Agent can enter terminal commands.
* **Key Advantages**: Keeps the prompt clean and concise; the Agent presents a structured table of project IDs, names, and balances, saving to `project.md`.

---

### 📌 Prompt 3: Verify Specific Project Code (GOV115088)

```text
Which of the following Partitions can project GOV115088 use? Please help confirm, thank you!
`ngs8g` / `ngs16g` / `ngs32g` / `ngs62g` / `ngs125g`

Please perform the following verification steps:
1. Run `sacctmgr -nP show assoc user="$USER" account="gov115088"` to verify Slurm association authorization.
2. Run `scontrol show partition` to inspect the AllowAccounts / DenyAccounts policies for `ngs8g` / `ngs16g` / `ngs32g` / `ngs62g` / `ngs125g`, verifying whether `GOV115088` can submit to these Partitions (Note: Currently only `ngs62g` is allowed; `ngs8g` etc. are unavailable).
3. As this biomedical project may not appear in standard `wallet` listings, explain the check results and include a compatibility table.
Output the result to permission.md
```

#### 📖 Explanation & Mechanics:
* **Purpose**: Verifies whether a specific project (e.g., dedicated biomedical project `GOV115088`) holds scheduler-level submission and partition access rights, avoiding misjudgments from `wallet` alone.
* **No-Skill Mechanism**: Eliminates third-party skill dependencies, instructing the AI to use Slurm native database tool `sacctmgr` and node controller `scontrol`.
* **Key Advantages**: Gives the AI explicit execution steps so it accurately validates Account-Partition policies even in environments without custom skills, writing results to `permission.md`.

---

### 📌 Prompt 4: Bioinformatics FASTQ QC Analysis & Slurm Job Submission

```text
Please assist in creating and submitting a FASTQ bio-analysis job:
1. Automatically generate a test FASTQ file `data/test_sample.fastq` containing 1,000 reads under the `data/` directory (if FASTQ files already exist in the project, use existing files).
2. Create a Python script `script/fastq_qc_stats.py` under `script/` to read the FASTQ file and calculate total read count, average read length, and GC content %.
3. Write a Slurm submission script under `script/` with partition set to `ngs62g`, directing logs to `logs/`; do not hardcode the project account in version-controlled scripts.
4. Verify that `logs/` directory exists, validate `GOV115088` and `ngs62g` permissions, and use `sbatch --account="GOV115088"` to submit the job, reporting the Job ID and output inspection steps.
Output the analysis process and results to report.md
```

#### 📖 Explanation & Mechanics:
* **Purpose**: Implements an end-to-end automated workflow from data generation, writing Python analysis scripts, composing Slurm job files, to job queuing and reporting.
* **No-Skill Mechanism**: Converts preflight checks into standard Linux commands (ensuring `logs/` folder creation, permission validation, and parameter passing via `sbatch --account=...`).
* **Key Advantages**: Ensures 100% successful job submission in no-skill environments while maintaining security standards, recording process, job status, and QC outputs in `report.md`.

---

## 💡 Best Practices for AI Agents on HPC

1. **Pre-create Log Directories**: Slurm requires `--output` and `--error` log paths before job launch; ensure `logs/` directory exists beforehand.
2. **Pass Project Code Correctly**: Do not hardcode account IDs in tracked scripts; pass `--account="<PROJECT_ID>"` dynamically at submission time.
3. **Non-Polling Monitoring**: After job submission, use single checks like `squeue -j <JOB_ID>` or `sacct -j <JOB_ID>` instead of infinite background `sleep` loops.
