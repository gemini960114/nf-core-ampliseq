#!/bin/bash
#SBATCH --job-name=ampliseq_moving_pictures
#SBATCH --partition=ngs250g
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=250G
#SBATCH --output=logs/job-%j.out
#SBATCH --error=logs/job-%j.err
#SBATCH --mail-type=END,FAIL

# 1. 建立日誌資料夾
mkdir -p logs

# 2. 載入 HPC 官方環境模組
module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7

# 3. 設定提交作業帳號專用的 Singularity 快取目錄
export NXF_SINGULARITY_CACHEDIR="/work/${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3"
mkdir -p "$NXF_SINGULARITY_CACHEDIR"

echo "=== Ampliseq Job Started on $(date) ==="
echo "Running on host: $(hostname)"

# 4. 執行 Nextflow 分析流程
# 請從 nf-core-ampliseq 根目錄執行：
# sbatch --account="<PROJECT_ID>" 03_scripts/submit_ampliseq.slurm
cd "$SLURM_SUBMIT_DIR"
bash 03_scripts/prepare_samplesheet.sh

AMPLISEQ_PIPELINE="${AMPLISEQ_PIPELINE:-/work/${USER}/nf-core_download/ampliseq-2.18.0/2_18_0}"
AMPLISEQ_REFERENCE_STORAGE="${AMPLISEQ_REFERENCE_STORAGE:-/work/${USER}/reference_databases/ampliseq/silva-138.2}"

if [[ ! -f "${AMPLISEQ_PIPELINE}/main.nf" ]]; then
   echo "錯誤：找不到 ampliseq workflow：${AMPLISEQ_PIPELINE}" >&2
   echo "請先在登入節點執行：bash 03_scripts/prepare_assets.sh" >&2
   exit 1
fi

for reference_file in \
   silva_nr99_v138.2_toSpecies_trainset.fa.gz \
   silva_v138.2_assignSpecies.fa.gz
do
   if [[ ! -s "${AMPLISEQ_REFERENCE_STORAGE}/${reference_file}" ]]; then
      echo "錯誤：找不到 SILVA 參考檔：${AMPLISEQ_REFERENCE_STORAGE}/${reference_file}" >&2
      echo "請先在登入節點執行：bash 03_scripts/prepare_assets.sh" >&2
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
   --single_end \
   --trunclenf 120 \
   --metadata_category_barplot "body_site" \
   --qiime_adonis_formula "body_site" \
   --skip_phyloseq \
   --outdir "./results" \
   -resume

echo "=== Ampliseq Job Finished at $(date) ==="
