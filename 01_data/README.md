# 📂 01_data 數據與元數據資料夾

本資料夾包含 16S 擴增子分析流程所需的輸入數據與元數據檔。

---

## 📁 內容清單

1. **`samplesheet.template.tsv`**：34 個 Moving Pictures 單端樣本的可攜式樣品清單範本。
2. **`samplesheet.tsv`**：由 `03_scripts/prepare_samplesheet.sh` 依目前 clone 位置產生，包含 FASTQ 絕對路徑且不納入 Git。
3. **`metadata.tsv`**：Moving Pictures 實驗設計元數據表，第一欄為 `sampleID`，主要分組欄位為 `body_site`。
4. **`fastq/`**：Git 版本控制中的 34 個單端 16S rRNA FASTQ 範例檔。
