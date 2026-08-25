#!/bin/bash
#SBATCH --job-name=ampliseq_modules
#SBATCH --partition=ngs62g
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=250G
#SBATCH --time=48:00:00
#SBATCH --output=logs/job-%j.out
#SBATCH --error=logs/job-%j.err
#SBATCH --mail-type=END,FAIL

set -euo pipefail

on_exit() {
   status=$?
   if (( status == 0 )); then
      echo "=== Ampliseq Module Job Finished Successfully at $(date) ==="
   else
      echo "=== Ampliseq Module Job Failed with exit code ${status} at $(date) ===" >&2
   fi
}
trap on_exit EXIT

# 1. 建立日誌資料夾
mkdir -p logs

# 2. 載入 HPC 官方系統環境模組 (Environment Modules)
module purge
ml biology/qiime2/2026.7
ml biology/nf-core-ampliseq/2.18.0

echo "=== Ampliseq Module Job Started on $(date) ==="
echo "Running on host: $(hostname)"
echo "Using NFCORE_AMPLISEQ_HOME: ${NFCORE_AMPLISEQ_HOME}"
echo "Using NFCORE_SITE_CONFIG: ${NFCORE_SITE_CONFIG}"

# 3. 執行 Nextflow 分析流程 (使用系統站台提供之套件與設定)
cd "${SLURM_SUBMIT_DIR:?錯誤：SLURM_SUBMIT_DIR 未設定，請使用 sbatch 提交此腳本}"
bash 03_scripts/prepare_samplesheet.sh

nextflow run "$NFCORE_AMPLISEQ_HOME" \
   -c 02_config/nextflow_singularity.config \
   -c "$NFCORE_SITE_CONFIG" \
   -profile singularity \
   --input 01_data/samplesheet.tsv \
   --metadata 01_data/metadata.tsv \
   --dada_ref_taxonomy "silva=138.2" \
   --skip_cutadapt \
   --single_end \
   --trunclenf 120 \
   --metadata_category_barplot "body_site" \
   --qiime_adonis_formula "body_site" \
   --skip_phyloseq \
   --outdir "./results" \
   -resume
