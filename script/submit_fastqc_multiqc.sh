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

echo "Running FastQC on 01_data/fastq/*.fastq.gz with 8 threads..."
fastqc -t 8 01_data/fastq/*.fastq.gz -o results/fastqc/

echo "Running MultiQC to summarize FastQC reports..."
multiqc results/fastqc/ -o results/multiqc/

echo "=== FastQC & MultiQC Workflow Finished at $(date) ==="
