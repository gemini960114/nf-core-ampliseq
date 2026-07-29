# 🧬 16S 擴增子分析 - HPC 全手動操作指南 (Manual Execution Guide)
> 本手冊提供在國網中心 (NCHC) Slurm HPC 環境下，完全使用 Terminal 指令手動執行 `nf-core/ampliseq 2.18.0` 16S 微生物雙端定序分析的完整步驟。

---

## 📋 流程概覽與目錄

1. [環境模組與 Singularity 快取設定](#1-環境模組與-singularity-快取設定)
2. [離線資產預先準備 (Pipeline, Containers, SILVA)](#2-離線資產預先準備)
3. [數據下載與 FASTQ 檔案導出](#3-數據下載與-fastq-檔案導出)
4. [Metadata 校正與 Samplesheet 絕對路徑生成](#4-metadata-校正與-samplesheet-絕對路徑生成)
5. [Nextflow 關鍵配置檢驗](#5-nextflow-關鍵配置檢驗)
6. [Slurm 作業提交與非輪詢進度監控](#6-slurm-作業提交與進度監控)
7. [成果產出與 MultiQC 總報告查看](#7-成果產出與-multiqc-總報告查看)

---

## 1. 環境模組與 Singularity 快取設定

在登入節點開啟 Terminal，清空舊模組並載入 NCHC 官方 Nextflow 與 Singularity 模組：

```bash
# 1. 載入系統模組
module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7

# 2. 設定個人專用 Singularity 容器快取目錄
export NXF_SINGULARITY_CACHEDIR="/work/${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3"
mkdir -p "$NXF_SINGULARITY_CACHEDIR"
```

---

## 2. 離線資產預先準備

為了避免在計算節點執行時因為網路問題或併發下載下載失敗，請先在**登入節點**執行資產預備腳本：

```bash
# 執行資產準備腳本（自動下載 ampliseq 2.18.0、Singularity 映像檔與 SILVA 138.2 資料庫）
bash 03_scripts/prepare_assets.sh
```

---

## 3. 數據下載與 FASTQ 檔案導出

以 Gut-to-Soil (Meilander et al., 2024) 雙端定序數據為例：

```bash
# 1. 下載中繼資料 (Metadata) 與 QIIME 2 Demux Artifact (demux.qza)
wget -O 01_data/metadata.raw.tsv https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/sample-metadata.tsv
wget -O /tmp/demux.qza https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/demux.qza

# 2. 將 208 個雙端 FASTQ.gz 檔案解包導出至 01_data/fastq/
mkdir -p 01_data/fastq
rm -f 01_data/fastq/*.fastq.gz
unzip -o -j /tmp/demux.qza '*/data/*.fastq.gz' -d 01_data/fastq/
rm -f /tmp/demux.qza
```

---

## 4. Metadata 校正與 Samplesheet 絕對路徑生成

為了符合 `nf-core/ampliseq` 的 Schema 規範（Sample ID 需補上英文字母開頭 `S_`、欄位名稱減號轉底線）：

```bash
# 1. 執行 Metadata 格式修復與 Sample ID 規範化
python3 03_scripts/prepare_gut_to_soil.py
python3 03_scripts/clean_metadata.py

# 2. 產生包含完整絕對路徑的 samplesheet.tsv
bash 03_scripts/prepare_samplesheet.sh
```

---

## 5. Nextflow 關鍵配置檢驗

請確認專案根目錄下的 [nextflow.config](nextflow.config) 與 [02_config/nextflow_singularity.config](02_config/nextflow_singularity.config) 包含以下設定：

```groovy
singularity {
    enabled     = true
    autoMounts  = true
    runOptions  = '-B /tmp:/tmp' // 修復 QIIME 2 Rachis Python 暫存隔離問題
}

process {
    executor = 'local' // 確保子任務在配給節點內執行，避免 sbatch 扣款失敗
    beforeScript = '''
        mkdir -p "$PWD/.nxf-tmp"
        export TMPDIR="$PWD/.nxf-tmp"
        export TMP="$TMPDIR"
        export TEMP="$TMPDIR"
    '''.stripIndent().trim()
}
```

---

## 6. Slurm 作業提交與進度監控

確保日誌目錄存在，並使用您的 Slurm 計畫代碼（如 `MST109178`）提交作業至 `ngs250g` 高記憶體分割區：

```bash
# 1. 建立日誌資料夾
mkdir -p logs

# 2. 執行 Nano4 read-only preflight
bash .agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh \
  --project "MST109178" --partition "ngs250g"

# 3. 提交 Slurm 作業
sbatch --account="MST109178" 03_scripts/submit_ampliseq.slurm

# 4. 查詢作業狀態
squeue -u $USER

# 4. 即時查看執行日誌 (將 <JOB_ID> 替換為實際 Job ID)
tail -f logs/job-<JOB_ID>.out
```

---

## 7. 成果產出與 MultiQC 總報告查看

分析完成後，所有結果會存放在 `./results/` 目錄：

- **MultiQC 網頁總報告**：`results/multiqc/multiqc_report.html`
- **DADA2 ASV 表與物種分類**：`results/dada2/ASV_table.tsv` 與 `ASV_tax.silva_138_2.tsv`
- **QIIME 2 多樣性與物種圖表**：`results/qiime2/`
