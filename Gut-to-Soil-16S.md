# 🧬 Gut-to-Soil 16S 雙端擴增子菌相分析 - AI Prompt 提示詞庫與實作指南

本文件提供將 **Gut-to-Soil (腸道至土壤微生態軸, Meilander et al., 2024)** 16S V4 雙端定序數據帶入本專案，並委託 **AI Agent** 進行全自動化 HPC 分析、數據處理、Slurm 任務派送與成果繪圖的完整提示詞（Prompt）與數據規格手冊。

---

## 🌐 一、 數據來源與技術數值規格 (Data Sources & Parameters)

### 1. 原始資料下載連結 (Data URLs)
- **中繼資料 (Sample Metadata)**：
  `https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/sample-metadata.tsv`
- **雙端定序數據 (Demultiplexed QIIME 2 Artifact)**：
  `https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/demux.qza`

### 2. 核心技術參數與修正規範 (Technical Parameters & Fixes)
- **定序模式與標的基因**：16S rRNA V4 區段 (F515-R806 增幅引物)，雙端定序 (Paired-End 2x250 bp)。
- **樣品規模**：104 個雙端 FASTQ 樣品 (208 個 `.fastq.gz` 檔案)。
- **DADA2 去噪與剪裁參數**：
  - 前端不剪裁：`--trim-left-f 0 --trim-left-r 0`
  - 雙端截斷長度：`--trunclenf 250 --trunclenr 250`
- **Schema 驗證與前綴修復 (Sample ID Fix)**：
  - `nf-core/ampliseq` 要求 Sample ID 必須以英文字母開頭（Regex: `^[a-zA-Z][a-zA-Z0-9_]+$`）。
  - 所有 Sample ID 在 `samplesheet.tsv` 與 `metadata.tsv` 中均補上 **`S_` 前綴**（如 `016287d9` $\rightarrow$ `S_016287d9`）。
- **空白樣品防護標籤**：
  - 加入 `--ignore_empty_input_files`，自動略過 Reads 數小於 1 條之無效/空白樣品（如 `S_48dff3fa`）。
- **統計檢定與單一樣本修復 (Singletons Fix)**：
  - 指定繪圖與 Adonis 因子：`--metadata_category_barplot "SampleType"` 與 `--qiime_adonis_formula "SampleType"`。
  - 將 `SampleType` 中僅有 1 個樣品的單一組別（`Inside Transfer Bucket`、`Inside Composting Bucket`、`SunMar Microbe Mix`）合併標記為 `"Other Controls"`，防止 QIIME 2 `beta-group-significance` 統計崩潰。

---

## 💬 二、 AI Agent 自然語言提示詞庫 (Prompt Library)

學員或研究人員可複製以下提示詞發送給 AI Agent，AI 將自動調用 `.agents/skills/slurm_ampliseq_guide` 技能並精準重現所有分析結果：

### 1. ⭐ 推薦：全流程一鍵自動化派送與監控 Prompt (One-Prompt Full Automation)

```text
請參考 slurm_ampliseq_guide 技能，幫我將 Gut-to-Soil 16S 雙端定序數據帶入本專案進行分析。
我的 Slurm 計畫代碼是 <PROJECT_ID>。

請協助執行以下步驟：
1. 從以下 URL 下載數據並放至 01_data/：
   - Metadata: https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/sample-metadata.tsv
   - Demux Artifact: https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/demux.qza
2. 將 demux.qza 解包為 FASTQ.gz 檔案放至 01_data/fastq/。
3. 將 Metadata 儲存為 01_data/metadata.raw.tsv，依序執行 03_scripts/prepare_gut_to_soil.py 與 03_scripts/clean_metadata.py。
4. 執行 03_scripts/prepare_samplesheet.sh 產生雙端 samplesheet.tsv（含 S_ 前綴與 fastq_1/fastq_2 絕對路徑）。
5. 確認 03_scripts/submit_ampliseq.slurm 設定 --trunclenf 250 --trunclenr 250、--ignore_empty_input_files、--metadata_category_barplot "SampleType"、--qiime_adonis_formula "SampleType"。
6. 提交 sbatch 並在背景進行非輪詢式監控，完成後告訴我 1,070 ASVs 的產出結果與 MultiQC 總報告連結。
```

---

### 2. 📥 階段一：數據下載與格式化 Prompt (Data Ingestion & Cleaning)

```text
請幫我下載 Gut-to-Soil 數據集並進行標準化格式處理：
1. 下載 sample-metadata.tsv 至 01_data/metadata.raw.tsv。
2. 下載 demux.qza 並將裡面的 208 個 FASTQ.gz 檔案解包導出至 01_data/fastq/。
3. 依序執行 03_scripts/prepare_gut_to_soil.py、03_scripts/clean_metadata.py 與 03_scripts/prepare_samplesheet.sh。
```

---

### 3. 🚀 階段二：Slurm 腳本配置與任務派送 Prompt (Pipeline Execution)

```text
請幫我配置並提交 Gut-to-Soil 16S 雙端分析的 Slurm 批次作業：
1. 我的計畫代碼是 <PROJECT_ID>，請使用 ngs250g 分割區。
2. 確保 submit_ampliseq.slurm 設定：
   - 雙端模式 (移除 --single_end)
   - --trunclenf 250 --trunclenr 250
   - --ignore_empty_input_files (自動略過 Reads 小於 1 之樣品)
   - --metadata_category_barplot "SampleType"
   - --qiime_adonis_formula "SampleType"
3. 使用 sbatch 提交任務並啟動背景計時器追蹤進度。
```

---

### 4. 📝 階段三：自動撰寫 Markdown 分析報告 Prompt (Report Generation)

```text
分析任務完成後，請讀取 results/overall_summary.tsv、results/dada2/ASV_seqs.fasta 與 QIIME 2 統計結果，為我撰寫一份詳細的 16S 擴增子分析結果總結報告，輸出至 04_viewer/report.md。
內容需包含輸入資料規格 (104 個雙端樣品)、1,070 個 ASVs 產出量、SILVA 138.2 物種分類結果與 PERMANOVA (p=0.001) 統計解讀。
```

---

### 5. 🌐 階段四：啟動整合型 Web 儀表板 Prompt (Web Dashboard Launcher)

```text
請幫我啟動專案的 Python HTTP Web Server (開啟在 port 8000)，並告訴我如何在本地電腦透過 SSH Port Forwarding 開啟 04_viewer/index.html 瀏覽整合型暗黑擬態儀表板與 3D Emperor PCoA 圖表。
```

---

## 📊 三、 實測重現標竿成果數據 (Verified Benchmark Results)

當 AI Agent 依據上述 Prompt 完成執行後，您預期獲得的標竿數據如下：

| 項目 | 實測數據 / 成果連結 |
| :--- | :--- |
| **Slurm 任務 ID** | Job `210413` (運行節點: `25a-cpn01`, 分割區: `ngs250g`) |
| **總執行時間** | **10 分 59 秒** (完成 39 個子任務 + 325 個快取任務) |
| **雙端樣品總數** | **104 個樣品** (208 個 `.fastq.gz` 檔) |
| **去噪 ASV 總數** | **1,070 個 ASVs** (DADA2 250 bp 雙端拼接去嵌合體) |
| **物種分類資料庫** | **SILVA 138.2** (屬與物種層級精細分類) |
| **PERMANOVA 檢定** | 不同 `SampleType` 之間菌群結構差異極顯著 (**$p = 0.001$**) |
| **MultiQC 總報告** | [results/multiqc/multiqc_report.html](../results/multiqc/multiqc_report.html) |
| **Pipeline 摘要簡報** | [results/summary_report/summary_report.html](../results/summary_report/summary_report.html) |
| **QIIME 2 柱狀圖** | [results/qiime2/barplot/index.html](../results/qiime2/barplot/index.html) |
| **QIIME 2 稀疏曲線** | [results/qiime2/alpha-rarefaction/index.html](../results/qiime2/alpha-rarefaction/index.html) |
| **整合網頁儀表板** | [04_viewer/index.html](04_viewer/index.html) |
