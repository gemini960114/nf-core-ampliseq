# 💬 03_scripts：LLM AI Agent 自然語言提示詞指令庫

本文件收錄可直接複製使用之 AI Prompt 提示詞，指導 LLM Agent 自動化完成 Slurm 腳本生成、資源動態配置、任務派送與背景監控。

---

## 🎯 實用自然語言 Prompt 範例

### 範例一：標準派送與自動監控指令
> **使用者輸入**：  
> 「請先使用 `nano4-slurm-operations` 驗證我的 `<PROJECT_ID>` 與 `ngs62g`，再使用 `slurm-ampliseq-guide` 派送 repository 內建的 34 個 Moving Pictures 單端樣本。請確認 samplesheet、metadata 與 FASTQ 一致，在登入節點準備 ampliseq 2.18.0、Singularity images 與 SILVA 138.2；preflight 通過後提交並以非輪詢方式監控，最後提供 MultiQC 與成果連結。」

### 範例二：調整 Moving Pictures 計算資源
> **使用者輸入**：  
> 「請使用 34 個 Moving Pictures 單端樣本與 SILVA 138.2。我的計畫是 `<PROJECT_ID>`，目標是 `<PARTITION>`；請先用 `nano4-slurm-operations` 驗證該組合是否允許 16 CPUs、64G RAM 與所需 walltime。只有 preflight 通過才產生對應的 Slurm 腳本並提交，不要改用 ITS、18S 或 paired-end 參數。」

---

## 🤖 LLM Agent 的內部自動處理機制

當 AI Agent 收到上述指令後，會在背景自動執行以下 4 個步驟：

1. **資源與參數解析**：讀取使用者指定的 Slurm 計畫代碼、計算資源 (CPU/Memory/Partition) 與物種資料庫，自動檢查 `samplesheet.tsv`、`metadata.tsv` 與 `nextflow.config`。
2. **提交任務**：先建立 `logs/` 並在登入節點執行 `bash 03_scripts/prepare_assets.sh`，再以 `sbatch --account="<PROJECT_ID>" 03_scripts/submit_ampliseq.slurm` 取得 Slurm Job ID（如 `Job 209473`）。
3. **背景非輪詢式監控**：使用 `schedule(DurationSeconds=45)` 定時喚醒檢查 `logs/job-%j.out`，避免無效 sleep 迴圈。
4. **驗證與交稿**：偵測到 `Pipeline completed successfully` 時，自動提供 `multiqc_report.html` 與 `summary_report.html` 網頁連結。
