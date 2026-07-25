# 💬 03_scripts：LLM AI Agent 自然語言提示詞指令庫

本文件收錄可直接複製使用之 AI Prompt 提示詞，指導 LLM Agent 自動化完成 Slurm 腳本生成、資源動態配置、任務派送與背景監控。

---

## 🎯 實用自然語言 Prompt 範例

### 範例一：標準派送與自動監控指令
> **使用者輸入**：  
> 「請參考 `slurm_ampliseq_guide` 技能，使用我的 Slurm 計畫代碼 `<PROJECT_ID>`，幫我在 `ngs250g` 分割區派送一個 16S 擴增子分析任務。輸入目錄為目前專案下的 `01_data/`；請先以 `pwd` 取得專案絕對路徑，並確認 samplesheet 內的 FASTQ 路徑有效。請在登入節點使用 uv 預先準備 ampliseq 2.18.0、Singularity images 與 SILVA 138.2，再生成 Slurm 腳本、提交 `sbatch` 並在背景監控進度。完成後告訴我 MultiQC 網頁總報告與成果連結。」

### 範例二：指定計算資源與特定資料庫 (彈性資源設定)
> **使用者輸入**：  
> 「請使用我的 Slurm 計畫代碼 `<PROJECT_ID>`，幫我用 UNITE 9.0 資料庫跑目前專案下 `01_data/` 的真菌定序資料；請先以 `pwd` 取得專案絕對路徑。請彈性指定 16 核 CPU / 64G 記憶體派送工作至 Slurm，設定個人 Singularity cache，並在結束時提供網頁報告連結。」

---

## 🤖 LLM Agent 的內部自動處理機制

當 AI Agent 收到上述指令後，會在背景自動執行以下 4 個步驟：

1. **資源與參數解析**：讀取使用者指定的 Slurm 計畫代碼、計算資源 (CPU/Memory/Partition) 與物種資料庫，自動檢查 `samplesheet.tsv`、`metadata.tsv` 與 `nextflow.config`。
2. **提交任務**：先建立 `logs/` 並在登入節點執行 `bash 03_scripts/prepare_assets.sh`，再以 `sbatch --account="<PROJECT_ID>" 03_scripts/submit_ampliseq.slurm` 取得 Slurm Job ID（如 `Job 209473`）。
3. **背景非輪詢式監控**：使用 `schedule(DurationSeconds=45)` 定時喚醒檢查 `logs/job-%j.out`，避免無效 sleep 迴圈。
4. **驗證與交稿**：偵測到 `Pipeline completed successfully` 時，自動提供 `multiqc_report.html` 與 `summary_report.html` 網頁連結。
