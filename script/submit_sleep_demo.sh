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

# 切換工作目錄至提交時的目錄
if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    cd "${SLURM_SUBMIT_DIR}"
fi

mkdir -p logs

echo "=== Sleep Job started at $(date) ==="
echo "Host: $(hostname)"
echo "Sleeping for 300 seconds..."

sleep 300

echo "=== Sleep Job finished at $(date) ==="