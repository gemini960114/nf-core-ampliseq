# 🎓 Slurm Job Submission & Bioinformatics QC Workflow Tutorial
> **Tutorial 5: Hands-on Guide to Slurm Job Scheduling and FASTQ QC Analysis**

This tutorial is designed for HPC (High Performance Computing) environments such as the NCHC Nano4 cluster using the Slurm Workload Manager. It includes three step-by-step practical cases and detailed syntax explanations suitable for training courses.

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

## 🧪 Case 1: Job Queueing Test & Resource Occupancy Demo (Sleep 300s)

This case helps students understand the full lifecycle of Slurm jobs: queueing, running, and manual cancellation.

### 1. Create Submission Script `script/submit_sleep_demo.sh`

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

### 2. Submit & Monitor Queue
```bash
sbatch --account="GOV115088" script/submit_sleep_demo.sh
squeue -u $USER
```

---

## 🧬 Case 2: FASTQ Quality Control & GC Content Statistics

This case demonstrates calculating total reads, average read length, and GC content % using a Python script.

### 1. Full Allocation Submission Script 8 Cores / 62GB (`script/submit_fastq_qc.sh`)

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

### 2. Submit Job:
```bash
sbatch --account="GOV115088" script/submit_fastq_qc.sh
```

---

## 🔬 Case 3: Real Bioinformatics Workflow – FastQC + MultiQC Batch Analysis

This case demonstrates using HPC Environment Modules (`module load`) to execute FastQC on all 34 FASTQ files using 8 threads and generating an interactive HTML report with MultiQC.

### 1. Check Available HPC Modules (`module avail` / `ml av`)
Use `ml av` on the login node to view pre-installed software modules:
* `biology/JDK/26.0.1` (Java runtime required by FastQC)
* `biology/FastQC/0.11.9` (FASTQ quality control tool)
* `biology/MultiQC/1.35` (Multi-sample report aggregator)

### 2. Create Submission Script `script/submit_fastqc_multiqc.sh`

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

# Load required environment modules
module load biology/JDK/26.0.1
module load biology/FastQC/0.11.9
module load biology/MultiQC/1.35

echo "Running FastQC on 34 FASTQ files with 8 threads..."
fastqc -t 8 01_data/fastq/*.fastq.gz -o results/fastqc/

echo "Running MultiQC to summarize FastQC reports..."
multiqc results/fastqc/ -o results/multiqc/

echo "=== FastQC & MultiQC Workflow Finished at $(date) ==="
```

### 3. Submission & Results Verification

#### (1) Submit the job:
```bash
sbatch --account="GOV115088" script/submit_fastqc_multiqc.sh
```

#### (2) Monitor progress:
```bash
squeue -u $USER
```

#### (3) View output HTML report:
Once completed, the interactive HTML report is generated in `results/multiqc/`:
```text
results/multiqc/multiqc_report.html
```

---

## ❓ Frequently Asked Questions (FAQ)

1. **Q: Why pass `--account="GOV115088"` on the command line?**
   * A: NCHC requires every job to be billed to a specific project ID. Passing it dynamically via CLI avoids committing sensitive or personal project IDs into version-controlled Git repositories.
2. **Q: What happens if I omit `#SBATCH --mem`?**
   * A: If `--mem` is omitted, Slurm attempts to request the whole physical node memory by default, exceeding the `ngs62g` QoS 62GB limit and locking the job in `PD (QOSMaxMemoryPerJob)`.
3. **Q: Why load `biology/JDK` before running FastQC?**
   * A: FastQC is a Java application. HPC environments use dynamic module loading; loading JDK provides the standard Java runtime environment required by FastQC.
