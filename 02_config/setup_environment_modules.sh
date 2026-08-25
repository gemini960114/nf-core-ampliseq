#!/bin/bash
set -euo pipefail

# ==============================================================================
#  國網中心 (NCHC) 官方預建系統模組 (Environment Modules) 載入腳本
# ==============================================================================

echo "=== 1. 清空舊模組並載入 NCHC 官方預建系統模組 ==="
module purge
ml biology/qiime2/2026.7
ml biology/nf-core-ampliseq/2.18.0

echo "=== 2. 檢查模組載入狀態與環境變數 ==="
echo "Nextflow 指令位置: $(which nextflow)"
echo "QIIME 2 指令位置:   $(which qiime)"
echo "Pipeline 離線源碼:  ${NFCORE_AMPLISEQ_HOME}"
echo "站台 Slurm 設定檔:  ${NFCORE_SITE_CONFIG}"
echo "QIIME 2 分類器目錄: ${QIIME2_CLASSIFIER_ROOT}"
