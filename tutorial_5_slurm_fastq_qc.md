# 🎓 Slurm 作業派送實務教學指南：從佇列測試到 FASTQ 生物資訊 QC 分析
> **Tutorial 5: Slurm Job Submission & Bioinformatics QC Workflow Guide**

本指南針對國網中心 (NCHC) Nano4 叢集與 Slurm 作業調度系統設計，適合生物資訊與高效能運算 (HPC) 課程教學使用。包含兩個循序漸進的實作案例與詳細語法解析。

---

## 📋 課程導覽與實作目標

| 案例 | 主題 | 學習重點 | 指令與腳本 | 關鍵概念 |
| :--- | :--- | :--- | :--- | :--- |
| **案例一** | **作業佇列測試與資源佔用實驗** | 學習 `sbatch` 派送、佇列觀察與作業取消 | `sleep 300`<br>`script/submit_sleep_demo.sh` | `squeue` 狀態 (`PD`/`R`), `scancel` |
| **案例二** | **FASTQ 統計與 GC 含量計算** | 生物資訊數據品質檢測與多核心高記憶體派送 | `python3`<br>`script/submit_fastq_qc.sh` | `--cpus-per-task=8`, `--mem=62G` |

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

# 切換工作目錄至提交時的目錄
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

### 2. 派送作業
```bash
sbatch --account="GOV115088" script/submit_sleep_demo.sh
```
*終端機輸出範例：* `Submitted batch job 298516`

### 3. 觀察佇列狀態 (`squeue`)
```bash
squeue -u $USER
```
*佇列狀態代碼說明：*
* `ST = PD` (Pending)：作業正在佇列中等待資源調度。
* `ST = R` (Running)：作業已取得節點（如 `25a-cpn01`）並正在執行中。
* `ST = CG` (Completing)：作業執行完畢，系統正在清理資源。

### 4. 練習手動取消作業 (`scancel`)
當作業仍在排隊或執行時，若需要中止作業可執行：
```bash
scancel <JOB_ID>
# 例如：scancel 298516
```

---

## 🧬 案例二：FASTQ 生物資訊品質檢測與 GC 含量統計

本案例演示真實生物資訊資料的品質檢測 (QC) 流程，計算總 Read 筆數、平均讀長與 GC 含量 %。

### 1. 自動產生測試 FASTQ 檔 (`data/test_sample.fastq`)
由範例資料擷取 1,000 條 Reads (4,000 行)：
```bash
mkdir -p data script logs
zcat 01_data/fastq/L1S57.fastq.gz | head -n 4000 > data/test_sample.fastq
```

### 2. QC 統計 Python 腳本 (`script/fastq_qc_stats.py`)

```python
#!/usr/bin/env python3
import sys
import os
import gzip

def analyze_fastq(file_path):
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' does not exist.", file=sys.stderr)
        sys.exit(1)

    is_gz = file_path.endswith('.gz')
    open_fn = gzip.open if is_gz else open

    total_reads = 0
    total_length = 0
    gc_count = 0

    with open_fn(file_path, 'rt') as f:
        line_num = 0
        for line in f:
            line_num += 1
            mod = line_num % 4
            if mod == 2:  # 序列資料列
                seq = line.strip().upper()
                total_reads += 1
                total_length += len(seq)
                gc_count += seq.count('G') + seq.count('C')

    if total_reads == 0:
        print("Warning: No reads found in the FASTQ file.", file=sys.stderr)
        return

    avg_len = total_length / total_reads
    gc_content = (gc_count / total_length * 100) if total_length > 0 else 0.0

    print("========================================")
    print("        FASTQ QC Statistics Report      ")
    print("========================================")
    print(f"File Path          : {file_path}")
    print(f"Total Reads        : {total_reads:,}")
    print(f"Total Bases        : {total_length:,} bp")
    print(f"Average Read Length: {avg_len:.2f} bp")
    print(f"GC Content (%)     : {gc_content:.2f}%")
    print("========================================")

if __name__ == "__main__":
    target_file = sys.argv[1] if len(sys.argv) > 1 else "data/test_sample.fastq"
    analyze_fastq(target_file)
```

### 3. 8 核 / 62GB 滿配額度提交腳本 (`script/submit_fastq_qc.sh`)

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
echo "Working directory: $(pwd)"

python3 script/fastq_qc_stats.py data/test_sample.fastq

echo "=== Job finished at $(date) ==="
```

### 4. 派送與成果檢視

#### (1) 派送作業：
```bash
sbatch --account="GOV115088" script/submit_fastq_qc.sh
```

#### (2) 檢視歷史作業會計紀錄 (`sacct`)：
```bash
sacct -j <JOB_ID> --format=JobID,JobName,Partition,Account,ReqCPUs,ReqMem,State,ExitCode
```

#### (3) 檢視分析成果日誌：
```bash
cat logs/fastq_qc_<JOB_ID>.out
```

*預期產出內容：*
```text
=== Job started at Tue Aug 25 10:14:02 AM CST 2026 ===
Host: 25a-cpn01
Working directory: /work/c00cjz00/nf-core-ampliseq
========================================
        FASTQ QC Statistics Report      
========================================
File Path          : data/test_sample.fastq
Total Reads        : 1,000
Total Bases        : 152,000 bp
Average Read Length: 152.00 bp
GC Content (%)     : 50.67%
========================================
=== Job finished at Tue Aug 25 10:14:02 AM CST 2026 ===
```

---

## ❓ 常見問與答 (FAQ)

1. **Q: 為什麼派送時必須加 `--account="GOV115088"`？**
   * A: 國網中心主機規定所有作業必須明確歸屬給特定計畫扣抵額度。為了防止將帳號硬編碼入 Git 版控腳本導致點數洩漏，採用命令列參數傳入為最佳實務。
2. **Q: 不寫 `#SBATCH --mem` 會發生什麼事？**
   * A: 若未設定 `--mem`，Slurm 會預設為該節點全額記憶體，因而超過 `ngs62g` 分割區單一作業的 62GB 限制，導致作業持續停留在 `PD (QOSMaxMemoryPerJob)` 狀態。
