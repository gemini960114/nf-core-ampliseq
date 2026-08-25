# 🎓 Slurm 作業派送實務教學指南：從佇列測試到 FASTQ 生物資訊 QC 分析
> **Tutorial 5: Slurm Job Submission & Bioinformatics QC Workflow Guide**

本指南針對國網中心 (NCHC) Nano4 叢集與 Slurm 作業調度系統設計，適合生物資訊與高效能運算 (HPC) 課程教學使用。包含三個循序漸進的實作案例與詳細語法解析。

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

## 🧪 案例一：作業佇列測試與資源佔用實驗 (Sleep 300 秒)

本案例幫助學員了解 Slurm 排隊、執行中與手動取消作業的完整生命週期。

### 1. 建立腳本 `script/submit_sleep_demo.sh`

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

### 2. 派送與佇列觀察
```bash
sbatch --account="GOV115088" script/submit_sleep_demo.sh
squeue -u $USER
```

---

## 🧬 案例二：FASTQ 生物資訊品質檢測與 GC 含量統計

本案例演示使用 Python 腳本計算總 Read 筆數、平均讀長與 GC 含量 %。

### 1. 8 核 / 62GB 滿配額度提交腳本 (`script/submit_fastq_qc.sh`)

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

### 2. 派送作業：
```bash
sbatch --account="GOV115088" script/submit_fastq_qc.sh
```

---

## 🔬 案例三：真實生物資訊分析 – FastQC + MultiQC 批次品質分析

本案例示範如何呼叫 HPC 內建的環境模組（Environment Modules, `module load`），對專案中所有的 FASTQ 定序資料（34 個樣本）進行 8 核多執行緒 FastQC 分析，並使用 MultiQC 產出互動式 HTML 圖表報告。

### 1. 查詢 HPC 內建模組 (`module avail` / `ml av`)
在登入節點上可使用 `ml av` 查詢系統預裝之軟體：
* `biology/JDK/26.0.1` (Java 執行環境，FastQC 依賴)
* `biology/FastQC/0.11.9` (FASTQ 品質分析工具)
* `biology/MultiQC/1.35` (多樣本報告彙整工具)

### 2. 建立提交腳本 `script/submit_fastqc_multiqc.sh`

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

# 載入所需的環境模組
module load biology/JDK/26.0.1
module load biology/FastQC/0.11.9
module load biology/MultiQC/1.35

echo "Running FastQC on 34 FASTQ files with 8 threads..."
fastqc -t 8 01_data/fastq/*.fastq.gz -o results/fastqc/

echo "Running MultiQC to summarize FastQC reports..."
multiqc results/fastqc/ -o results/multiqc/

echo "=== FastQC & MultiQC Workflow Finished at $(date) ==="
```

### 3. 派送與檢視成果

#### (1) 派送作業：
```bash
sbatch --account="GOV115088" script/submit_fastqc_multiqc.sh
```

#### (2) 檢視執行進度：
```bash
squeue -u $USER
```

#### (3) 檢視產出之 HTML 報告：
作業完成後，整合報告將產出於 `results/multiqc/` 目錄：
```text
results/multiqc/multiqc_report.html
```

---

## ❓ 常見問與答 (FAQ)

1. **Q: 為什麼派送時必須加 `--account="GOV115088"`？**
   * A: 國網中心主機規定所有作業必須明確歸屬給特定計畫扣抵額度。為了防止將帳號硬編碼入 Git 版控腳本導致點數洩漏，採用命令列參數傳入為最佳實務。
2. **Q: 不寫 `#SBATCH --mem` 會發生什麼事？**
   * A: 若未設定 `--mem`，Slurm 會預設為該節點全額記憶體，因而超過 `ngs62g` 分割區單一作業的 62GB 限制，導致作業持續停留在 `PD (QOSMaxMemoryPerJob)` 狀態。
3. **Q: 為什麼執行 FastQC 前要 `module load biology/JDK`？**
   * A: FastQC 是基於 Java 開發的軟體，HPC 環境中軟體採動態模組管理，載入 JDK 才能為 FastQC 提供標準的 Java 執行環境。
