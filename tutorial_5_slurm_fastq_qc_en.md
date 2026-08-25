# 🎓 Slurm Job Submission & Bioinformatics QC Workflow Tutorial
> **Tutorial 5: Hands-on Guide to Slurm Job Scheduling and FASTQ QC Analysis**

This tutorial is designed for HPC (High Performance Computing) environments such as the NCHC Nano4 cluster using the Slurm Workload Manager. It includes two step-by-step practical cases and detailed syntax explanations suitable for training courses.

---

## 📋 Course Overview & Objectives

| Case | Topic | Learning Objectives | Command & Scripts | Key Concepts |
| :--- | :--- | :--- | :--- | :--- |
| **Case 1** | **Queue Testing & Resource Occupancy** | Practice `sbatch` submission, queue monitoring, and job cancellation | `sleep 300`<br>`script/submit_sleep_demo.sh` | `squeue` states (`PD`/`R`), `scancel` |
| **Case 2** | **FASTQ Statistics & GC Content Calculation** | Bioinformatics quality control (QC) and multi-core high-memory submission | `python3`<br>`script/submit_fastq_qc.sh` | `--cpus-per-task=8`, `--mem=62G` |

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

# Change working directory to submission location
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

### 2. Submit the Job
```bash
sbatch --account="GOV115088" script/submit_sleep_demo.sh
```
*Sample output:* `Submitted batch job 298527`

### 3. Monitor Queue Status (`squeue`)
```bash
squeue -u $USER
```
*Status Codes Explanation:*
* `ST = PD` (Pending): The job is waiting in queue for resource allocation.
* `ST = R` (Running): The job has allocated resources (e.g. node `25a-cpn01`) and is running.
* `ST = CG` (Completing): The job is finishing and cleaning up resources.

### 4. Practice Manual Job Cancellation (`scancel`)
To cancel a queued or running job:
```bash
scancel <JOB_ID>
# Example: scancel 298527
```

---

## 🧬 Case 2: FASTQ Quality Control & GC Content Statistics

This case demonstrates a real bioinformatics QC workflow calculating total reads, average read length, and GC content %.

### 1. Generate 1,000 Reads Test FASTQ (`data/test_sample.fastq`)
Sample 1,000 reads (4,000 lines) from example data:
```bash
mkdir -p data script logs
zcat 01_data/fastq/L1S57.fastq.gz | head -n 4000 > data/test_sample.fastq
```

### 2. Python QC Statistics Script (`script/fastq_qc_stats.py`)

```python
#!/usr/bin/env python3
import sys
import os
import gzip

def analyze_fastq(file_path):
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' does not exist.", file=sys.stderr)
        sys.exit(1)

    is_gz = file_path.endswith('.gz')
    open_fn = gzip.open if is_gz else open

    total_reads = 0
    total_length = 0
    gc_count = 0

    with open_fn(file_path, 'rt') as f:
        line_num = 0
        for line in f:
            line_num += 1
            mod = line_num % 4
            if mod == 2:  # Sequence line
                seq = line.strip().upper()
                total_reads += 1
                total_length += len(seq)
                gc_count += seq.count('G') + seq.count('C')

    if total_reads == 0:
        print("Warning: No reads found in the FASTQ file.", file=sys.stderr)
        return

    avg_len = total_length / total_reads
    gc_content = (gc_count / total_length * 100) if total_length > 0 else 0.0

    print("========================================")
    print("        FASTQ QC Statistics Report      ")
    print("========================================")
    print(f"File Path          : {file_path}")
    print(f"Total Reads        : {total_reads:,}")
    print(f"Total Bases        : {total_length:,} bp")
    print(f"Average Read Length: {avg_len:.2f} bp")
    print(f"GC Content (%)     : {gc_content:.2f}%")
    print("========================================")

if __name__ == "__main__":
    target_file = sys.argv[1] if len(sys.argv) > 1 else "data/test_sample.fastq"
    analyze_fastq(target_file)
```

### 3. Full Allocation Submission Script 8 Cores / 62GB (`script/submit_fastq_qc.sh`)

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
echo "Working directory: $(pwd)"

python3 script/fastq_qc_stats.py data/test_sample.fastq

echo "=== Job finished at $(date) ==="
```

### 4. Job Submission & Results Verification

#### (1) Submit the job:
```bash
sbatch --account="GOV115088" script/submit_fastq_qc.sh
```

#### (2) Inspect accounting history (`sacct`):
```bash
sacct -j <JOB_ID> --format=JobID,JobName,Partition,Account,ReqCPUs,ReqMem,State,ExitCode
```

#### (3) View QC statistics output log:
```bash
cat logs/fastq_qc_<JOB_ID>.out
```

*Sample expected output:*
```text
=== Job started at Tue Aug 25 10:18:00 AM CST 2026 ===
Host: 25a-cpn01
Working directory: /work/c00cjz00/nf-core-ampliseq
========================================
        FASTQ QC Statistics Report      
========================================
File Path          : data/test_sample.fastq
Total Reads        : 1,000
Total Bases        : 152,000 bp
Average Read Length: 152.00 bp
GC Content (%)     : 50.67%
========================================
=== Job finished at Tue Aug 25 10:18:00 AM CST 2026 ===
```

---

## ❓ Frequently Asked Questions (FAQ)

1. **Q: Why pass `--account="GOV115088"` on the command line?**
   * A: NCHC requires every job to be billed to a specific project ID. Passing it dynamically via CLI avoids committing sensitive or personal project IDs into version-controlled Git repositories.
2. **Q: What happens if I omit `#SBATCH --mem`?**
   * A: If `--mem` is omitted, Slurm attempts to request the whole physical node memory by default, exceeding the `ngs62g` QoS 62GB limit and locking the job in `PD (QOSMaxMemoryPerJob)`.
