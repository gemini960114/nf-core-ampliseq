# Moving Pictures 16S：AI Agent Prompt 與結果解讀

本提示詞庫以 repository 內建的 34 個 Moving Pictures 單端 FASTQ 為唯一
預設資料集。提交前必須使用 Nano4 preflight 驗證使用者指定的計畫與
partition。

## 1. 一鍵準備與提交

```text
請使用 nano4-slurm-operations 與 slurm-ampliseq-guide，分析目前
repository 內建的 34 個 Moving Pictures 單端 FASTQ。

我的 Slurm 計畫代碼是 <PROJECT_ID>，目標 partition 是 ngs62g。
請先執行 read-only preflight；若計畫、association 或 partition policy
不相容，請停止且不要提交。

請依序：
1. 確認 01_data/fastq 有 34 個 L*.fastq.gz。
2. 確認 samplesheet.template.tsv 為 sample、fastq_1 兩欄，且 sample ID
   與 metadata.tsv 第一欄一致。
3. 執行 03_scripts/prepare_samplesheet.sh。
4. 在登入節點執行 03_scripts/prepare_assets.sh。
5. 驗證 submit_ampliseq.slurm 使用 --single_end、--trunclenf 120，
   並以 body_site 進行 barplot 與 Adonis。
6. 使用 sbatch --account="<PROJECT_ID>" 提交，回報 Job ID，並以非輪詢
   方式監控。
```

## 2. 分階段提示詞

### 輸入資料驗證

```text
請唯讀檢查 Moving Pictures 教學資料：FASTQ 必須正好 34 個；
samplesheet.template.tsv 必須是單端格式；metadata 必須包含相同 sample ID
及 body_site。不要下載或替換資料。
```

### 資產準備與環境檢查（含 `uv`）

```text
請檢查登入節點環境是否已安裝 `uv`（若未安裝，請執行 `curl -LsSf https://astral.sh/uv/install.sh | sh` 隨後執行 `source ~/.bashrc` 載入 PATH）。

請在登入節點執行 03_scripts/prepare_assets.sh。資產必須存入目前帳號自己的 `/work/${USER}/` 目錄，不要使用其他帳號的 cache。

準備完成後，請使用我的計畫 <PROJECT_ID> 與 ngs62g 執行 Nano4 preflight。通過後，以 Moving Pictures 單端參數提交 03_scripts/submit_ampliseq.slurm，回報 Job ID。
```

## 3. 分析後 Q&A

### QC 與 DADA2

```text
請讀取 MultiQC 與 DADA2 stats，整理 34 個 Moving Pictures 樣本的 reads
保留率、異常低深度樣本與最終 ASV 數量。請引用實際輸出，不要沿用示範數字。
```

### Alpha／Beta 多樣性

```text
請依 body_site 比較 gut、tongue、left palm、right palm 的 Alpha 多樣性，
並從實際 Adonis/PERMANOVA 輸出整理 R²、p-value 與限制。
```

### Taxonomy

```text
請讀取 ASV_table.tsv 與 ASV_tax.silva_138_2.tsv，整理主要菌門與菌屬，
並比較不同 body_site；區分資料直接支持的結果與生物學推論。
```

### 圖表與報告

```text
請執行 03_scripts/phyloseq_analysis.R，以 body_site 繪製相對豐度與
Bray-Curtis PCoA，並將依實際結果撰寫的報告儲存到 04_viewer/report.md。
```
