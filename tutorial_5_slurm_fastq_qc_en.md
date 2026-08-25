# 🎓 Slurm Job Submission & Bioinformatics QC Workflow Tutorial
> **Tutorial 5: Hands-on Guide to Slurm Job Scheduling and FASTQ QC Analysis**

This tutorial is designed for HPC (High Performance Computing) environments such as the NCHC Nano4 cluster using the Slurm Workload Manager. It includes both traditional Bash CLI instructions and **AI Agent Natural Language Prompts**.

---

## 📋 Course Overview & Objectives

| Case | Topic | Learning Objectives | Command & Scripts | Key Concepts |
| :--- | :--- | :--- | :--- | :--- |
| **Case 1** | **Queue Testing & Resource Occupancy** | Practice `sbatch` submission, queue monitoring, and job cancellation | `sleep 300`<br>`script/submit_sleep_demo.sh` | `squeue` states (`PD`/`R`), `scancel` |
| **Case 2** | **FASTQ Statistics & GC Content Calculation** | Bioinformatics quality control (QC) and multi-core high-memory submission | `python3`<br>`script/submit_fastq_qc.sh` | `--cpus-per-task=8`, `--mem=62G` |
| **Case 3** | **Batch FastQC & MultiQC Workflow** | Use HPC environment `module load` to load bioinformatics software and generate HTML reports | `module load`<br>`script/submit_fastqc_multiqc.sh` | `biology/FastQC`, `biology/MultiQC`, `biology/JDK` |

---

## ⚙️ Key Slurm Directive Syntax Reference

Lines starting with `#SBATCH` at the top of a Bash script are interpreted by the Slurm workload manager:

| Directive | Description | Tutorial Recommended Value | Notes / Constraints |
| :--- | :--- | :--- | :--- |
| `#SBATCH --job-name` | Display name of the job | `fastq_qc_stats` | Easy identification in `squeue` |
| `#SBATCH --partition` | Target compute partition | `ngs62g` | Dedicated NGS genomics partition |
| `#SBATCH --cpus-per-task` | Requested CPU cores per task | `8` (or `2`) | `ngs62g` maximum limit is 8 cores |
| `#SBATCH --mem` | Total requested memory | `62G` (or `4G`) | **Required**; omitting causes `QOSMaxMemoryPerJob` queueing |
| `#SBATCH --time` | Maximum walltime limit (hh:mm:ss) | `00:10:00` | Job is terminated if time limit is exceeded |
| `#SBATCH --output` | Standard output log (`stdout`) | `logs/fastq_qc_%j.out` | `%j` is automatically replaced with Job ID |
| `#SBATCH --error` | Standard error log (`stderr`) | `logs/fastq_qc_%j.err` | Log path for error output |

> ⚠️ **Best Practice**: Do NOT hardcode `#SBATCH --account=...` inside version-controlled scripts. Pass your project ID dynamically at submission:
> ```bash
> sbatch --account="GOV115088" <script_path>
> ```

---

## 💻 Part 1: Traditional CLI Manual Commands

### 🧪 Case 1: Job Queueing Test & Resource Occupancy Demo (Sleep 300s)

#### 1. Create Submission Script `script/submit_sleep_demo.sh`

```bash
#!/usr/bin/env bash
#SBATCH --job-name=sleep_demo
#SBATCH --partition=ngs62g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:10:00
#SBATCH --output=logs/sleep_demo_%j.out
#SBATCH --error=logs/sleep_demo_%j.err

set -euo pipefail

if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    cd "${SLURM_SUBMIT_DIR}"
fi

mkdir -p logs

echo "=== Sleep Job started at $(date) ==="
echo "Host: $(hostname)"
echo "Sleeping for 300 seconds..."

sleep 300

echo "=== Sleep Job finished at $(date) ==="
```

#### 2. Submit & Monitor Queue
```bash
sbatch --account="GOV115088" script/submit_sleep_demo.sh
squeue -u $USER
```

---

### 🧬 Case 2: FASTQ Quality Control & GC Content Statistics

#### 1. Full Allocation Submission Script 8 Cores / 62GB (`script/submit_fastq_qc.sh`)

```bash
#!/usr/bin/env bash
#SBATCH --job-name=fastq_qc_stats
#SBATCH --partition=ngs62g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=62G
#SBATCH --time=00:10:00
#SBATCH --output=logs/fastq_qc_%j.out
#SBATCH --error=logs/fastq_qc_%j.err

set -euo pipefail

if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    cd "${SLURM_SUBMIT_DIR}"
fi

mkdir -p logs

echo "=== Job started at $(date) ==="
echo "Host: $(hostname)"

python3 script/fastq_qc_stats.py data/test_sample.fastq

echo "=== Job finished at $(date) ==="
```

#### 2. Submit Job:
```bash
sbatch --account="GOV115088" script/submit_fastq_qc.sh
```

---

### 🔬 Case 3: Real Bioinformatics Workflow – FastQC + MultiQC Batch Analysis

#### 1. Create Submission Script `script/submit_fastqc_multiqc.sh`

```bash
#!/usr/bin/env bash
#SBATCH --job-name=fastqc_multiqc
#SBATCH --partition=ngs62g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=62G
#SBATCH --time=00:15:00
#SBATCH --output=logs/fastqc_%j.out
#SBATCH --error=logs/fastqc_%j.err

set -euo pipefail

if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    cd "${SLURM_SUBMIT_DIR}"
fi

mkdir -p logs results/fastqc results/multiqc

echo "=== FastQC & MultiQC Workflow Started at $(date) ==="
echo "Host: $(hostname)"
echo "Loading environment modules..."

module load biology/JDK/26.0.1
module load biology/FastQC/0.11.9
module load biology/MultiQC/1.35

echo "Running FastQC on 34 FASTQ files with 8 threads..."
fastqc -t 8 01_data/fastq/*.fastq.gz -o results/fastqc/

echo "Running MultiQC to summarize FastQC reports..."
multiqc results/fastqc/ -o results/multiqc/

echo "=== FastQC & MultiQC Workflow Finished at $(date) ==="
```

#### 2. Submission & Results Verification:
```bash
sbatch --account="GOV115088" script/submit_fastqc_multiqc.sh
```

##### 💡 Best Ways to View the HTML Report:
1. **IDE Right-Click Download (Recommended ⭐️)**: Locate `results/multiqc/multiqc_report.html` in the file tree, **right-click** and select **`Download...`** to save locally and open in your browser.
2. **SSH Tunnel Web Server**: Run `python3 -m http.server 8000 --bind 127.0.0.1` and open `http://localhost:8000/results/multiqc/multiqc_report.html` via SSH tunnel.

---

## 🤖 Part 2: AI Agent Natural Language Workflow (Prompt Library)

Students or researchers do not need to manually write Shell scripts or memorize commands. Simply copy the following **Natural Language Prompts** to an AI Agent with Terminal / Slurm capabilities (e.g. Antigravity AI, Cursor, Claude Code), and the AI will automatically handle preflight checks, script generation, `sbatch` submission, and status reporting!

---

### 📌 AI Prompt 1: Case 1 – Queue Testing & Resource Occupancy Demo

```text
Please create a Slurm queue testing script script/submit_sleep_demo.sh under script/.
Parameters: partition ngs62g, memory 4G, CPU 2 cores, walltime 10 mins, logs to logs/.
Script body: execute sleep 300 seconds.
After creating the script, please run Nano4 Slurm Preflight check to verify project GOV115088 and ngs62g partition permissions.
Upon confirmation, submit the job with sbatch --account="GOV115088" script/submit_sleep_demo.sh, and report the Job ID and squeue status commands.
```

#### 💡 AI Behavior:
* **AI Action**: Creates the file, populates `#SBATCH` headers, runs preflight verification, submits via `sbatch`, and reports the job status.

---

### 📌 AI Prompt 2: Case 2 – FASTQ Sampling, Python Statistics & 8-Core Allocation

```text
Please help me complete a FASTQ quality control statistics job:
1. Extract the first 1,000 reads (4,000 lines) from 01_data/fastq/L1S57.fastq.gz to create data/test_sample.fastq.
2. Create Python script script/fastq_qc_stats.py under script/ to read FASTQ and calculate total reads count, average read length, and GC content %.
3. Create Slurm submission script script/submit_fastq_qc.sh (setting 8 CPU cores, 62GB memory, partition ngs62g, logs to logs/), making sure account is not hardcoded.
4. Run preflight check, submit with sbatch --account="GOV115088" upon success, and display the final QC statistics results log to me.
```

#### 💡 AI Behavior:
* **AI Action**: Extracts sample data, writes and tests the Python script, creates the Slurm script, runs preflight, submits the job, and displays output statistics from `logs/`.

---

### 📌 AI Prompt 3: Case 3 – Batch FastQC + MultiQC Workflow & Report Generation

```text
Please create and submit a complete FastQC and MultiQC bioinformatics quality control job:
1. Create Slurm script script/submit_fastqc_multiqc.sh under script/ targeting partition ngs62g with 8 CPU cores and 62GB memory.
2. Load required HPC environment modules: biology/JDK/26.0.1, biology/FastQC/0.11.9, and biology/MultiQC/1.35.
3. Run FastQC with 8 threads on all 34 files in 01_data/fastq/*.fastq.gz to results/fastqc/, then run MultiQC to summarize reports at results/multiqc/multiqc_report.html.
4. Perform preflight checks, submit with sbatch --account="GOV115088".
5. Upon job completion, report the Job ID and explain how to right-click Download... the HTML report in the IDE file tree.
```

#### 💡 AI Behavior:
* **AI Action**: Resolves correct module names, creates directory structure, submits job, tracks status via `sacct` until completion, and guides HTML report download.

---

## ❓ Frequently Asked Questions (FAQ)

1. **Q: Why pass `--account="GOV115088"` on the command line?**
   * A: NCHC requires every job to be billed to a specific project ID. Passing it dynamically via CLI avoids committing sensitive or personal project IDs into version-controlled Git repositories.
2. **Q: What happens if I omit `#SBATCH --mem`?**
   * A: If `--mem` is omitted, Slurm attempts to request the whole physical node memory by default, exceeding the `ngs62g` QoS 62GB limit and locking the job in `PD (QOSMaxMemoryPerJob)`.
3. **Q: Why load `biology/JDK` before running FastQC?**
   * A: FastQC is a Java application. HPC environments use dynamic module loading; loading JDK provides the standard Java runtime environment required by FastQC.
