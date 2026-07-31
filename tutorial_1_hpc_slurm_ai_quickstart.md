# 🚀 HPC Slurm AI Agent 快速入門與 Prompt 提示詞指南
> **HPC & Slurm AI-Assisted Bio-Analysis Quickstart Guide**

本指南提供適用於國網中心 (NCHC) / Slurm HPC 環境的 AI Agent 自然語言提示詞（Prompts）。您可以直接複製以下 Prompt 發送給 AI Agent，自動完成 HPC 資源查詢、計畫授權確認與生物資訊分析作業派送。

> 本章的 1,000-read 合成 FASTQ 是獨立 Slurm 入門練習，只使用 `data/`
> 與 `script/`；不會修改 `01_data/` 的 34 個 Moving Pictures 主範例。

---

## 📋 快速導覽清單

| 階段 | 步驟 | 任務目標 | 核心工具 / 指令 |
| :--- | :--- | :--- | :--- |
| **一、環境與資源查詢** | **Prompt 1** | 查詢可使用的 Slurm Partition 資源與硬體限制 | `sinfo` / `scontrol` |
| | **Prompt 2** | 使用 `wallet` 指令列出可用計畫代碼與額度 | `wallet` |
| | **Prompt 3** | 確認特定計畫代碼 (`GOV115088`) 與 NGS partition 權限 | `wallet` / `sacctmgr` / `scontrol` |
| **二、生物資訊分析派送** | **Prompt 4** | 自動產生測試資料、編寫 Python 統計腳本並派送 Slurm Job | `sbatch` / Python / `ngs62g` |

---

## 💬 獨立 Prompt 提示詞庫

### 📌 Prompt 1：查詢 Slurm Partition 資源
> **用途**：讓 AI Agent 自動檢查 HPC 上所有可派送的分割區（Partition）、節點狀態與 CPU/記憶體上限。

```text
請協助檢查並列出目前這台 HPC 上我可以使用的所有 Slurm Partition 資源。
請使用 `sinfo` 或相關指令，整理出各 Partition 的名稱、節點數量、狀態（如 idle/alloc），以及各自的 CPU 核心數與記憶體限制。
```

---

### 📌 Prompt 2：使用 wallet 指令查詢計畫代碼
> **用途**：讓 AI Agent 自動查詢您名下的所有國網/HPC 計畫代碼（Project ID / Account）與點數餘額。

```text
請執行 `wallet` 指令，列出目前我所擁有的所有 HPC 計畫代碼（Project ID / Account），並幫我整理出各計畫的可用額度與狀態。
```

---

### 📌 Prompt 3：確認特定計畫代碼 (GOV115088)
> **用途**：驗證指定計畫代碼是否存在、是否有效，並確認其於各 NGS Partition (`ngs8g`/`ngs16g`/`ngs32g`/`ngs62g`/`ngs125g`) 的派送權限。

```text
請使用 nano4-slurm-operations 技能，幫我確認計畫 `GOV115088` 可以使用下列哪些 Partition：
`ngs8g` / `ngs16g` / `ngs32g` / `ngs62g` / `ngs125g`
請確認 `GOV115088` 是否具有 Slurm association，並驗證各 Partition 的 AllowAccounts / DenyAccounts（註：目前僅 `ngs62g` 可用，`ngs8g` 等均不可用）。此生醫計畫可能不出現在一般 Nano4 wallet 清單中，請同時檢查 partition 政策，不要只依賴 wallet 結果。
```

---

### 📌 Prompt 4：生物資訊 FASTQ 統計分析與 Slurm 作業派送
> **用途**：完全自動化！AI 會自動生成 1,000 條 Read 測試 FASTQ 檔、撰寫 Python GC% 與讀長統計腳本、產生 Slurm 提交檔並派送至 `ngs62g` 分割區。

```text
請協助建立並派送一個 FASTQ 生物資訊分析作業：
1. 請在 `data/` 目錄下自動生成一個包含 1,000 條讀長（Reads）的測試用 FASTQ 檔案 `data/test_sample.fastq`（若專案中已存在 FASTQ 則直接使用現有檔案）。
2. 請在 `script/` 目錄下建立 Python 腳本 `script/fastq_qc_stats.py`，讀取上述 FASTQ 檔並統計序列總筆數、平均讀長（Read Length）與 GC 含量 %。
3. 在 `script/` 目錄下撰寫 Slurm 提交腳本，分割區為 `ngs62g`，將日誌寫入 `logs/`；不要把計畫代碼寫死在版本控制腳本。
4. 先執行 nano4-slurm-operations preflight，再使用 `sbatch --account="GOV115088"` 派送作業並回報 Job ID 與成果檢視方式。
```

---

## 💡 AI Agent 使用 HPC 的最佳實踐提示 (Best Practices)

1. **預先建立日誌目錄**：Slurm 在作業啟動前即需開啟 `--output` 與 `--error` 檔案，請確保 `logs/` 資料夾已預先建立。
2. **正確傳入計畫代碼**：不要在追蹤腳本中寫死帳號；提交時使用 `sbatch --account="<PROJECT_ID>" ...`。
3. **非輪詢式監控**：作業派送後，建議使用 `squeue -j <JOB_ID>` 查詢狀態，避免在背景使用 `sleep` 無限迴圈耗用資源。
