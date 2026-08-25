# 16S 擴增子分析：HPC 系統模組 (Environment Modules) 操作指南

本教學使用國網中心 (NCHC) Nano4 預建之官方系統模組 **`biology/qiime2/2026.7`** 與 **`biology/nf-core-ampliseq/2.18.0`**，搭配 repository 內建的 34 個 Moving Pictures 單端 FASTQ，以 Nextflow 與 Singularity 執行 16S 擴增子分析與後續 QIIME 2 互動式指令操作。

與 Tutorial 2（使用者自建快取與下載資產）不同，本範例直接利用 HPC 站台維護的離線封裝 Module，無需手動執行下載資產腳本，即可快速完成分析流程。

---

## 1. 系統模組 (Environment Modules) 簡介與優勢

在 Nano4 HPC 環境下，可以透過 Shell 的 `ml`（或 `module load`）直接載入系統安裝好的軟體套件與環境：

```bash
module purge
ml biology/qiime2/2026.7
ml biology/nf-core-ampliseq/2.18.0
```

載入這兩個模組後，系統會自動配置以下環境變數與指令：

1. **`biology/nf-core-ampliseq/2.18.0`**：
   - 自動載入 `biology/Nextflow/26.04.6` 與 `biology/nfcore_config`。
   - 提供預先封裝好的離線 Pipeline 目錄：`$NFCORE_AMPLISEQ_HOME`
     （路徑為 `/work/envstack/apps/application/biology/nf-core/pipelines/ampliseq/2.18.0/2_18_0`）。
   - 提供站台優化配置：`$NFCORE_SITE_CONFIG` 與物種庫參考點 `$NFCORE_SITE_REFERENCES`。
   - 提供系統快捷提交命令 `nfcore-submit`。
2. **`biology/qiime2/2026.7`**：
   - 提供完整建置好的 QIIME 2 2026.7 環境（包含物種分類器 `$QIIME2_CLASSIFIER_ROOT`）。
   - 可直接在 Command Line 執行 `qiime` 相關子命令。
   - 提供系統快捷提交工具 `qiime2-submit` 與 `qiime2-parallel-submit`。

---

## 2. Clone Repository 與輸入驗證

首先切換至個人工作目錄 `/work/$USER` 並 clone 本專案：

```bash
cd "/work/$USER"
git clone https://github.com/gemini960114/nf-core-ampliseq.git
cd nf-core-ampliseq

# 驗證 FASTQ 檔案數量（預期 34 個單端檔）
find 01_data/fastq -maxdepth 1 -name '*.fastq.gz' | wc -l

# 依目前 clone 位置產生包含絕對路徑的 samplesheet.tsv
bash 03_scripts/prepare_samplesheet.sh

# 檢視 samplesheet 與 metadata 標頭欄位
head -3 01_data/samplesheet.tsv
head -1 01_data/metadata.tsv
```

預期 FASTQ 數量為 34；`samplesheet.tsv` 欄位包含 `sample` 與 `fastq_1`；`metadata.tsv` 第一欄為 `sampleID`，並包含 `body_site` 分組資訊。

---

## 3. 驗證 Slurm 權限與腳本

將 `<PROJECT_ID>` 替換成你被授權使用的計畫代碼（例如 `GOV115088` 或一般計畫）。

在提交作業前，請先執行語法檢查與 Nano4 preflight 驗證：

```bash
bash -n 03_scripts/submit_ampliseq_module.slurm

bash .agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh \
  --project "<PROJECT_ID>" \
  --partition "ngs62g"
```

只有 preflight 完全通過才繼續提交。本教學提交腳本 ([03_scripts/submit_ampliseq_module.slurm](file:///work/c00cjz00/nf-core-ampliseq/03_scripts/submit_ampliseq_module.slurm)) 的 Moving Pictures 核心參數設定為：

- `-c "$NFCORE_SITE_CONFIG"`：載入系統站台 Slurm 資源動態選擇設定
- `--single_end`
- `--trunclenf 120`
- `--metadata_category_barplot "body_site"`
- `--qiime_adonis_formula "body_site"`

---

## 4. 提交批次作業與進度監控

確保日誌目錄 `logs/` 存在後提交作業：

```bash
mkdir -p logs
sbatch --account="<PROJECT_ID>" 03_scripts/submit_ampliseq_module.slurm
squeue -u "$USER"
```

取得 Job ID 後，可用以下指令單次查詢作業狀態（請勿使用無限 `sleep` 輪詢）：

```bash
sacct -j "<JOB_ID>" --format=JobID,State,ExitCode,Elapsed
```

---

## 5. 使用系統 `biology/qiime2/2026.7` 模組進行二次分析

當 Pipeline 完成後，你不需要再啟動 Singularity 容器，直接在 Shell 載入 `qiime2` 模組即可對產出的 `.qza` / `.qzv` 進行互動式操作或二次分析。

```bash
# 載入系統 QIIME 2 模組
ml biology/qiime2/2026.7

# 檢視 DADA2 產出的 FeatureTable Artefact 資訊
qiime tools peek results/qiime2/dada2_table.qza

# 匯出 Metadata 可視化圖表 (.qzv)
qiime metadata tabulate \
  --m-input-file 01_data/metadata.tsv \
  --o-visualization results/qiime2/metadata.qzv
```

---

## 6. 分析成果與 Web 可視化儀表板

分析完成後，主要的結果檔案包含：

- **MultiQC 品質總報告**：`results/multiqc/multiqc_report.html`
- **DADA2 ASV 豐度表與物種註釋**：`results/dada2/ASV_table.tsv` 與 `results/dada2/ASV_tax.silva_138_2.tsv`
- **QIIME 2 互動式圖表**：`results/qiime2/barplot/index.html` 與 `results/qiime2/diversity/`
- **整體序列統計總表**：`results/overall_summary.tsv`

### 瀏覽整合型 HTML Web 儀表板

在登入節點於專案根目錄啟動背景 HTTP 服務：

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory .
```

並於本機電腦建立 SSH port forwarding：

```bash
ssh -L 8000:localhost:8000 <ACCOUNT>@<HPC_LOGIN_HOST>
```

接著即可在個人電腦的瀏覽器直接開啟：
`http://localhost:8000/04_viewer/index.html` 切換檢視 MultiQC 報告、QIIME 2 柱狀圖、Alpha 稀疏曲線與 3D Beta PCoA 圖表。
