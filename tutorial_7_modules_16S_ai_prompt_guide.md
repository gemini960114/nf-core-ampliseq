# Moving Pictures 16S：HPC 系統模組 AI Agent Prompt 指南

本提示詞庫針對國網中心 (NCHC) Nano4 **系統環境模組 (`biology/qiime2/2026.7` 與 `biology/nf-core-ampliseq/2.18.0`)** 進行優化設計。透過載入站台預建的離線封裝 Module，AI Agent 可跳過下載資產步驟，直接於 Slurm HPC 執行 Moving Pictures 16S 單端資料分析與後續 QIIME 2 互動解讀。

---

## 1. 一鍵準備與提交 Prompt

```text
請使用 nano4-slurm-operations 與 slurm-ampliseq-guide，在 Nano4 上使用系統官方模組 biology/qiime2/2026.7 與 biology/nf-core-ampliseq/2.18.0 分析 repository 內建的 34 個 Moving Pictures 單端 FASTQ。

我的 Slurm 計畫代碼是 <PROJECT_ID>，目標 partition 是 ngs62g。
請先執行 read-only preflight；若計畫、association 或 partition policy 不相容，請停止且不要提交。

請依序：
1. 確認 01_data/fastq 有 34 個 L*.fastq.gz 檔案。
2. 執行 03_scripts/prepare_samplesheet.sh 產生包含絕對路徑的 samplesheet.tsv。
3. 載入系統模組 module purge && ml biology/qiime2/2026.7 biology/nf-core-ampliseq/2.18.0，並驗證 $NFCORE_AMPLISEQ_HOME 與 $NFCORE_SITE_CONFIG 環境變數是否正確設定。
4. 驗證 03_scripts/submit_ampliseq_module.slurm 腳本使用 --single_end、--trunclenf 120，並引用 $NFCORE_SITE_CONFIG 站台設定。
5. 使用 sbatch --account="<PROJECT_ID>" 03_scripts/submit_ampliseq_module.slurm 提交作業，回報 Job ID，並以非輪詢方式監控至完成。
6. 完成後回報 MultiQC 報告位置 (results/multiqc/multiqc_report.html)。
```

---

## 2. 分階段提示詞 (Multi-Stage Prompts)

### 輸入資料與模組環境檢查

```text
請檢查目前 Nano4 系統模組環境：
1. 執行 module avail 驗證 biology/qiime2/2026.7 與 biology/nf-core-ampliseq/2.18.0 是否可用。
2. 唯讀檢查 01_data/：確認 FASTQ 為 34 個單端檔，samplesheet.template.tsv 欄位正確，metadata.tsv 包含 sampleID 與 body_site。
3. 請勿手動下載資產或執行 prepare_assets.sh，直接確認系統離線 Package 位置。
```

### 系統模組作業提交與 preflight

```text
請載入系統模組 ml biology/qiime2/2026.7 biology/nf-core-ampliseq/2.18.0。

請使用我的計畫代碼 <PROJECT_ID> 與 partition ngs62g 執行 Nano4 Slurm preflight。通過後，以 sbatch --account="<PROJECT_ID>" 提交 03_scripts/submit_ampliseq_module.slurm，回報 Job ID，並設定背景監控通知。
```

### 系統 QIIME 2 模組互動分析 (不需要容器包裝)

```text
分析完成後，請直接載入 ml biology/qiime2/2026.7 模組：
1. 使用 qiime tools peek 檢視 results/qiime2/ 內的 DADA2 FeatureTable (.qza) 核心 metadata。
2. 執行 qiime metadata tabulate 產生 metadata 視覺化檔案 results/qiime2/metadata.qzv。
3. 整理出最主要的物種分類與 α/β 多樣性特徵，回報給使用者。
```

---

## 3. 分析後 Q&A 與結果解讀

### QC 與 DADA2 讀量保留率

```text
請讀取 MultiQC 與 DADA2 stats 表格 (results/dada2/DADA2_stats.tsv)，整理 34 個 Moving Pictures 樣本在 Input、Filtered、Denoised、Non-chimeric 階段的 reads 保留率與最終 ASV 數量。請引用實際輸出數據。
```

### Alpha / Beta 多樣性與 Adonis 統計

```text
請讀取 results/qiime2/diversity/ 內的分析結果，針對 body_site (gut, tongue, left palm, right palm) 比較 Alpha 多樣性 (Shannon / Faith PD)，並從 Adonis/PERMANOVA 輸出整理 R²、p-value 與顯著性差異解釋。
```

### 物種圖表與報告自動生成

```text
請讀取 results/ 內的分析結果，將整理好的全樣本數據總表寫入 results/overall_summary.tsv，並撰寫一份結構完整的分析總結報告存至 04_viewer/report.md。完成後告知如何開啓 04_viewer/index.html 儀表板。
```
