#!/bin/bash
#SBATCH --job-name=ampliseq_gut_to_soil
#SBATCH --partition=ngs250g
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
      echo "=== Gut-to-Soil Job Finished Successfully at $(date) ==="
   else
      echo "=== Gut-to-Soil Job Failed with exit code ${status} at $(date) ===" >&2
   fi
}
trap on_exit EXIT

module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7

export NXF_SINGULARITY_CACHEDIR="/work/${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3"
mkdir -p "$NXF_SINGULARITY_CACHEDIR"

cd "${SLURM_SUBMIT_DIR:?錯誤：SLURM_SUBMIT_DIR 未設定，請使用 sbatch 提交此腳本}"
bash 03_scripts/prepare_samplesheet.sh

AMPLISEQ_PIPELINE="${AMPLISEQ_PIPELINE:-/work/${USER}/nf-core_download/ampliseq-2.18.0/2_18_0}"
AMPLISEQ_REFERENCE_STORAGE="${AMPLISEQ_REFERENCE_STORAGE:-/work/${USER}/reference_databases/ampliseq/silva-138.2}"

if [[ ! -f "${AMPLISEQ_PIPELINE}/main.nf" ]]; then
   echo "錯誤：找不到 ampliseq workflow；請先執行 03_scripts/prepare_assets.sh" >&2
   exit 1
fi

for reference_file in \
   silva_nr99_v138.2_toSpecies_trainset.fa.gz \
   silva_v138.2_assignSpecies.fa.gz
do
   if [[ ! -s "${AMPLISEQ_REFERENCE_STORAGE}/${reference_file}" ]]; then
      echo "錯誤：找不到 SILVA 參考檔：${reference_file}" >&2
      exit 1
   fi
done

nextflow -c 02_config/nextflow_singularity.config run "$AMPLISEQ_PIPELINE" \
   -profile singularity \
   --input 01_data/samplesheet.tsv \
   --metadata 01_data/metadata.tsv \
   --dada_ref_taxonomy "silva=138.2" \
   --ref_taxonomy_storage "$AMPLISEQ_REFERENCE_STORAGE" \
   --skip_cutadapt \
   --ignore_empty_input_files \
   --trunclenf 250 \
   --trunclenr 250 \
   --metadata_category_barplot "SampleType" \
   --qiime_adonis_formula "SampleType" \
   --skip_phyloseq \
   --outdir "./results" \
   -resume
