# 🚀 HPC Slurm AI Agent 零門檻獨立入門指南 (無須 Git Clone)
> **HPC & Slurm Standalone AI-Assisted Quickstart Guide (No Repo / No Skill Required)**

本指南提供適用於國網中心 (NCHC) / Slurm HPC 環境的**通用版 AI Agent 提示詞 (Prompts)**。
**無需 `git clone` 本儲存庫，亦無需安裝任何客製化 Agent Skill**。您可以直接複製以下 Prompt 發送給任何具備 Terminal 執行權限的 AI Agent（例如 ChatGPT、Claude、Cursor、Antigravity 等），自動完成 HPC 資源查詢、計畫授權驗證與生物資訊分析作業派送，並各自產生結構化的 Markdown 報告檔案。

---

## 🧪 零環境準備的執行建議流程

使用者完全無需預先下載或 clone 任何專案檔案，只需登入 HPC 並在終端機輸入：

```bash
# 建立一個測試用的空白目錄並進入
mkdir -p ~/slurm_quickstart_test && cd ~/slurm_quickstart_test
```

隨後依序複製本指南中的 **Prompt 1 至 Prompt 4** 發送給 AI Agent，AI 就會自動完成從資源盤點、寫入測試檔案到成功派送 Slurm 作業的全部操作，並產出 4 個結果文件（`partition.md`, `project.md`, `permission.md`, `report.md`）！

---

## 📋 快速導覽清單

| 階段 | 步驟 | 任務目標 | 核心原生指令 | 產出檔案 |
| :--- | :--- | :--- | :--- | :--- |
| **一、環境與資源查詢** | **Prompt 1** | 查詢可使用的 Slurm Partition 資源與硬體限制 | `sinfo` / `scontrol` | `partition.md` |
| | **Prompt 2** | 使用 `wallet` 指令列出可用計畫代碼與額度 | `wallet` | `project.md` |
| | **Prompt 3** | 確認特定計畫代碼 (`MST109178`) 與 NGS partition 權限 | `sacctmgr` / `scontrol` | `permission.md` |
| **二、生物資訊分析派送** | **Prompt 4** | 自動產生測試資料、編寫 Python 統計腳本並派送 Slurm Job | `sbatch` / Python / `ngs8g` | `report.md` |

---

## 💬 獨立通用 Prompt 提示詞庫

### 📌 Prompt 1：查詢 Slurm Partition 資源

```text
請協助檢查並列出目前這台 HPC 上我可以使用的所有 Slurm Partition 資源。
請使用 `sinfo` 配合 `scontrol show partition` 指令，整理出各 Partition 的名稱、節點數量、狀態（如 UP/DOWN、idle/alloc），以及各自的 CPU 核心數、記憶體限制與最大執行時間 (MaxTime)。
並輸出為 partition.md
```

#### 📖 說明與原理：
* **用途**：讓 AI Agent 自動全面盤點 HPC 叢集上的分割區資源、硬體上限與當前節點狀態。
* **無 Skill 原理**：`sinfo` 與 `scontrol` 是 Slurm 資源調度器的原生 CLI 工具，任何 Linux 登入節點皆有內建，無需任何額外擴充 Skill。
* **優勢與特點**：要求 AI Agent 搭配 `scontrol show partition` 查詢，能避免僅解析 `sinfo` 而遺漏各 Partition 的時限與 Allow/DenyAccounts 詳細限制，並自動將盤點結果保存至 `partition.md`。

---

### 📌 Prompt 2：使用 wallet 指令查詢計畫代碼

```text
請執行 `wallet` 指令，列出目前我所擁有的所有 HPC 計畫代碼（Project ID / Account），並幫我整理出各計畫的可用額度與狀態。
並輸出為 project.md
```

#### 📖 說明與原理：
* **用途**：查詢使用者名下所有在國網/HPC 系統中註冊的計畫代碼（Project ID）與剩餘可用的 SU (Service Units) 點數。
* **無 Skill 原理**：`wallet` 是國網 HPC 系統原生的點數查詢工具（位於 `/usr/bin/wallet`），Agent 只要能在 Terminal 輸入命令即可直接執行。
* **優勢與特點**：Prompt 保持極簡，Agent 執行後會自動彙整表格呈現計畫代碼、計畫名稱與可用點數，並存檔為 `project.md`。

---

### 📌 Prompt 3：確認特定計畫代碼 (MST109178)

```text
請幫我確認生醫計畫代碼 `MST109178` 是否具有 Slurm 作業派送權限：
1. 請執行 `sacctmgr -nP show assoc user="$USER" account="mst109178"` 確認是否具備 Slurm association 授權。
2. 請執行 `scontrol show partition ngs8g` 檢查該 Partition 的 AllowAccounts / DenyAccounts 政策，驗證 `MST109178` 能否派送至 `ngs8g`。
3. 此生醫計畫可能不出現在一般 `wallet` 清單中，請同時說明檢查結果。
並輸出為 permission.md
```

#### 📖 說明與原理：
* **用途**：驗證特定計畫（例如專屬的生醫計畫 `MST109178`）是否擁有調度器層級的派送授權，避開單靠 `wallet` 查詢產生的誤判。
* **無 Skill 原理**：完全移除對第三方擴充技能的依賴，明確指示 AI 使用 Slurm 原生資料庫查詢指令 `sacctmgr` 與節點控制指令 `scontrol`。
* **優勢與特點**：給予 AI 明確的指令執行路徑，即使在沒有安裝專用 Skill 的環境下，AI 也能精確驗證 Account 與 Partition 之間的存取權限，並將結果輸出為 `permission.md`。

---

### 📌 Prompt 4：生物資訊 FASTQ 統計分析與 Slurm 作業派送

```text
請協助建立並派送一個 FASTQ 生物資訊分析作業：
1. 請在 `data/` 目錄下自動生成一個包含 1,000 條讀長（Reads）的測試用 FASTQ 檔案 `data/test_sample.fastq`（若專案中已存在 FASTQ 則直接使用現有檔案）。
2. 請在 `script/` 目錄下建立 Python 腳本 `script/fastq_qc_stats.py`，讀取上述 FASTQ 檔並統計序列總筆數、平均讀長（Read Length）與 GC 含量 %。
3. 在 `script/` 目錄下撰寫 Slurm 提交腳本，分割區設為 `ngs8g`，將日誌寫入 `logs/` 目錄；不要把計畫代碼硬編碼在版本控制腳本內。
4. 請先確認 `logs/` 目錄已建立，並驗證 `MST109178` 與 `ngs8g` 權限後，使用 `sbatch --account="MST109178"` 派送作業，並回報 Job ID 與成果檢視方式。
並將分析過程與結果輸出為 report.md
```

#### 📖 說明與原理：
* **用途**：實作端到端的自動化工作流，從資料生成、Python 分析腳本寫入、Slurm 任務檔撰寫到排程派送與回報。
* **無 Skill 原理**：將原腳本預檢步驟改為標準 Linux 流程（確保建立 `logs/` 目錄、權限檢查、並透過 `sbatch --account=...` 傳參提交）。
* **優勢與特點**：確保作業能在無 Skill 環境下 100% 成功提交，同時維持安全性規範，並將分析過程、作業狀態與 QC 結果完整寫入 `report.md`。

---

## 💡 AI Agent 使用 HPC 的最佳實踐提示 (Best Practices)

1. **預先建立日誌目錄**：Slurm 在作業啟動前即需開啟 `--output` 與 `--error` 檔案，請確保 `logs/` 資料夾已預先建立。
2. **正確傳入計畫代碼**：不要在版本控制腳本中寫死帳號；提交時使用命令行指定 `sbatch --account="<PROJECT_ID>" ...`。
3. **非輪詢式監控**：作業派送後，建議使用 `squeue -j <JOB_ID>` 或 `sacct -j <JOB_ID>` 單次查詢狀態，避免在背景使用 `sleep` 無限迴圈耗用資源。
