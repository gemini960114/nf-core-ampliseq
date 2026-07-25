#!/bin/bash
# ==============================================================================
#  第二步驟：HPC 環境模組載入與 Singularity 容器快取設定指令檔
# ==============================================================================

echo "=== 1. 清空舊模組並載入國網中心 (NCHC) 官方環境模組 ==="
module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7

echo "=== 2. 檢查軟體版本 ==="
nextflow -v
singularity --version

echo "=== 3. 設定目前登入帳號專用的 Singularity 快取目錄 ==="
export NXF_SINGULARITY_CACHEDIR="/work/${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3"
mkdir -p "$NXF_SINGULARITY_CACHEDIR"

echo "Singularity 個人快取目錄已指向: $NXF_SINGULARITY_CACHEDIR"
