# 🎓 Slurm 作業派送實務教學指南：從佇列測試到 FASTQ 生物資訊 QC 分析
> **Tutorial 5: Slurm Job Submission & Bioinformatics QC Workflow Guide**

本指南針對國網中心 (NCHC) Nano4 叢集與 Slurm 作業調度系統設計，適合生物資訊與高效能運算 (HPC) 課程教學使用。包含傳統 Bash 指令操作與 **AI Agent 自然語言提示詞 (Prompts)** 兩種教學模式。

---

## 📋 課程導覽與實作目標

| 案例 | 主題 | 學習重點 | 指令與腳本 | 關鍵概念 |
| :--- | :--- | :--- | :--- | :--- |
| **案例一** | **作業佇列測試與資源佔用實驗** | 學習 `sbatch` 派送、佇列觀察與作業取消 | `sleep 300`<br>`script/submit_sleep_demo.sh` | `squeue` 狀態 (`PD`/`R`), `scancel` |
| **案例二** | **FASTQ 統計與 GC 含量計算** | 生物資訊數據品質檢測與多核心高記憶體派送 | `python3`<br>`script/submit_fastq_qc.sh` | `--cpus-per-task=8`, `--mem=62G` |
| **案例三** | **FastQC + MultiQC 批次品質分析** | 使用 HPC 內建 `module` 載入生物資訊工具鏈並產出 HTML 互動報告 | `module load`<br>`script/submit_fastqc_multiqc.sh` | `biology/FastQC`, `biology/MultiQC`, `biology/JDK` |

---

## ⚙️ 核心 Slurm 參數語法解析

在 Bash 腳本開頭，以 `#SBATCH` 開頭的行會被 Slurm 讀取為排程參數：

| 參數 | 說明 | 本教學建議設定 | 備註 / 限制 |
| :--- | :--- | :--- | :--- |
| `#SBATCH --job-name` | 作業顯示名稱 | `fastq_qc_stats` | 方便在 `squeue` 中辨識 |
| `#SBATCH --partition` | 指定計算分割區 | `ngs62g` | 基因體定序專用分割區 |
| `#SBATCH --cpus-per-task` | 每個 Task 請求的 CPU 核心數 | `8` (或 `2`) | `ngs62g` 上限為 8 核 |
| `#SBATCH --mem` | 作業請求的記憶體總量 | `62G` (或 `4G`) | **必須指定**，否則會因預設全額超限而卡在 `QOSMaxMemoryPerJob` |
| `#SBATCH --time` | 作業執行時間上限 (hh:mm:ss) | `00:10:00` | 超時會被系統自動強制結束 |
| `#SBATCH --output` | 標準輸出日誌檔名 (`stdout`) | `logs/fastq_qc_%j.out` | `%j` 自動替換為 Slurm Job ID |
| `#SBATCH --error` | 標準錯誤日誌檔名 (`stderr`) | `logs/fastq_qc_%j.err` | 存放錯誤訊息 |

> ⚠️ **重要規範**：請勿在版本控制的腳本內寫死 `#SBATCH --account=...`。請在終端機派送時使用命令列帶入：
> ```bash
> sbatch --account="GOV115088" <腳本路徑>
> ```

---

## 💻 第一部分：傳統 CLI 手動指令實作演練

### 🧪 案例一：作業佇列測試與資源佔用實驗 (Sleep 300 秒)

#### 1. 建立腳本 `script/submit_sleep_demo.sh`

```bash
#!/usr/bin/env bash
#SBATCH --job-name=sleep_demo
#SBATCH --partition=ngs62g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:10:00
#SBATCH --output=logs/sleep_demo_%j.out
#SBATCH --error=logs/sleep_demo_%j.err

set -euo pipefail

if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    cd "${SLURM_SUBMIT_DIR}"
fi

mkdir -p logs

echo "=== Sleep Job started at $(date) ==="
echo "Host: $(hostname)"
echo "Sleeping for 300 seconds..."

sleep 300

echo "=== Sleep Job finished at $(date) ==="
```

#### 2. 派送與佇列觀察
```bash
sbatch --account="GOV115088" script/submit_sleep_demo.sh
squeue -u $USER
```

---

### 🧬 案例二：FASTQ 生物資訊品質檢測與 GC 含量統計

#### 1. 8 核 / 62GB 滿配額度提交腳本 (`script/submit_fastq_qc.sh`)

```bash
#!/usr/bin/env bash
#SBATCH --job-name=fastq_qc_stats
#SBATCH --partition=ngs62g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=62G
#SBATCH --time=00:10:00
#SBATCH --output=logs/fastq_qc_%j.out
#SBATCH --error=logs/fastq_qc_%j.err

set -euo pipefail

if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    cd "${SLURM_SUBMIT_DIR}"
fi

mkdir -p logs

echo "=== Job started at $(date) ==="
echo "Host: $(hostname)"

python3 script/fastq_qc_stats.py data/test_sample.fastq

echo "=== Job finished at $(date) ==="
```

#### 2. 派送作業：
```bash
sbatch --account="GOV115088" script/submit_fastq_qc.sh
```

---

### 🔬 案例三：真實生物資訊分析 – FastQC + MultiQC 批次品質分析

#### 1. 建立提交腳本 `script/submit_fastqc_multiqc.sh`

```bash
#!/usr/bin/env bash
#SBATCH --job-name=fastqc_multiqc
#SBATCH --partition=ngs62g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=62G
#SBATCH --time=00:15:00
#SBATCH --output=logs/fastqc_%j.out
#SBATCH --error=logs/fastqc_%j.err

set -euo pipefail

if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    cd "${SLURM_SUBMIT_DIR}"
fi

mkdir -p logs results/fastqc results/multiqc

echo "=== FastQC & MultiQC Workflow Started at $(date) ==="
echo "Host: $(hostname)"
echo "Loading environment modules..."

module load biology/JDK/26.0.1
module load biology/FastQC/0.11.9
module load biology/MultiQC/1.35

echo "Running FastQC on 34 FASTQ files with 8 threads..."
fastqc -t 8 01_data/fastq/*.fastq.gz -o results/fastqc/

echo "Running MultiQC to summarize FastQC reports..."
multiqc results/fastqc/ -o results/multiqc/

echo "=== FastQC & MultiQC Workflow Finished at $(date) ==="
```

#### 2. 派送與檢視成果：
```bash
sbatch --account="GOV115088" script/submit_fastqc_multiqc.sh
```

##### 💡 瀏覽 HTML 報告的最佳方式：
1. **IDE 右鍵一鍵下載（最直覺推薦 ⭐️）**：在左側檔案樹找到 `results/multiqc/multiqc_report.html` **按右鍵**選擇 **`Download...`** 下載至本機雙擊開啟。
2. **SSH Tunnel 網頁伺服器連線**：執行 `python3 -m http.server 8000 --bind 127.0.0.1` 並建立隧道，造訪 `http://localhost:8000/results/multiqc/multiqc_report.html`。

---

## 🤖 第二部分：AI Agent 自然語言互動演練 (Prompt 提示詞庫)

學員或研究員無需手動撰寫 Shell 腳本與記憶繁瑣指令，只需複製以下**自然語言提示詞 (Prompts)** 發送給具備 Terminal / Slurm 執行權限的 AI Agent（例如 Antigravity AI, Cursor, Claude Code 等），AI 即可自動完成 preflight 驗證、腳本撰寫、`sbatch` 派送與成果回報！

---

### 📌 AI Prompt 1：案例一 – 佇列測試與資源佔用實驗

```text
請協助我在 script/ 目錄下建立一個 Slurm 佇列測試腳本 script/submit_sleep_demo.sh。
要求參數為：分割區 ngs62g、記憶體 4G、CPU 2 核、執行時間 10 分鐘，將日誌寫入 logs/。
腳本內容為執行 sleep 300 秒。
撰寫完成後，請先執行 Nano4 Slurm Preflight 檢查確認計畫代碼 GOV115088 與 ngs62g 分割區權限無誤。
確認無誤後，請使用 sbatch --account="GOV115088" script/submit_sleep_demo.sh 派送作業，並回報 Job ID 與 squeue 狀態查詢指令。
```

#### 💡 AI 運作說明：
* **AI 行為**：自動建立檔案、補全 `#SBATCH` 標頭、執行 preflight 腳本，最後透過 `sbatch` 提交作業並回報狀態。

---

### 📌 AI Prompt 2：案例二 – FASTQ 數據抽樣、Python 統計與 8 核滿配派送

```text
請協助我完成 FASTQ 品質統計作業：
1. 請從 01_data/fastq/L1S57.fastq.gz 自動擷取前 1,000 條 Reads (4,000 行) 生成測試檔 data/test_sample.fastq。
2. 請在 script/ 目錄下建立 Python 腳本 script/fastq_qc_stats.py，讀取 FASTQ 檔並統計總 Reads 筆數、平均讀長與 GC 含量 %。
3. 撰寫 Slurm 提交腳本 script/submit_fastq_qc.sh，使用 ngs62g 分割區、8 核 CPU、62GB 記憶體，將日誌寫入 logs/，注意不要在腳本寫死 account。
4. 先執行 preflight 檢查，確認無誤後使用 sbatch --account="GOV115088" 派送執行，並直接讀取輸出日誌將統計結果報告呈現給我。
```

#### 💡 AI 運作說明：
* **AI 行為**：自動進行資料解壓切片、撰寫 Python 解析器並本機測試、撰寫 Slurm 腳本、進行 preflight 驗證、派送 Slurm 任務，待任務完成後自動讀取 `logs/` 顯示統計結果。

---

### 📌 AI Prompt 3：案例三 – 批次生物資訊分析 (FastQC + MultiQC 整合)

```text
請協助建立並派送一個完整的 FastQC 與 MultiQC 生物資訊品質分析作業：
1. 請在 script/ 目錄下建立 Slurm 提交腳本 script/submit_fastqc_multiqc.sh，指定分割區為 ngs62g、8 核 CPU、62GB 記憶體。
2. 在腳本中載入 HPC 環境模組：biology/JDK/26.0.1、biology/FastQC/0.11.9 與 biology/MultiQC/1.35。
3. 對 01_data/fastq/*.fastq.gz 目錄下所有 34 個檔案以 8 執行緒平行跑 FastQC，並將結果輸出至 results/fastqc/，接著執行 MultiQC 將報告彙整至 results/multiqc/multiqc_report.html。
4. 先進行 Preflight 檢測，確認無誤後使用 sbatch --account="GOV115088" 派送作業。
5. 作業完成後，請回報 Job ID 並說明如何在 IDE 檔案樹右鍵選取 Download... 下載 HTML 報告。
```

#### 💡 AI 運作說明：
* **AI 行為**：自動尋找正確的 `module` 名稱、建立輸出目錄結構、發送 Slurm 作息、動態追蹤 `sacct` 狀態至完成，並提供 HTML 報告下載指引。

---

## ❓ 常見問與答 (FAQ)

1. **Q: 為什麼派送時必須加 `--account="GOV115088"`？**
   * A: 國網中心主機規定所有作業必須明確歸屬給特定計畫扣抵額度。為了防止將帳號硬編碼入 Git 版控腳本導致點數洩漏，採用命令列參數傳入為最佳實務。
2. **Q: 不寫 `#SBATCH --mem` 會發生什麼事？**
   * A: 若未設定 `--mem`，Slurm 會預設為該節點全額記憶體，因而超過 `ngs62g` 分割區單一作業的 62GB 限制，導致作業持續停留在 `PD (QOSMaxMemoryPerJob)` 狀態。
3. **Q: 為什麼執行 FastQC 前要 `module load biology/JDK`？**
   * A: FastQC 是基於 Java 開發的軟體，HPC 環境中軟體採動態模組管理，載入 JDK 才能為 FastQC 提供標準的 Java 執行環境。
