# 🧬 16S 微生物菌群擴增子分析 (nf-core/ampliseq) - HPC 與 AI 自動化實作指南

本專案提供在 **國網中心 Nano4 Slurm HPC** 環境下，結合 **AI Coding
Agent** 與 **`nf-core/ampliseq`（16S 擴增子分析流程）** 的完整教學範例。

## 🧭 從這裡開始

### 教材資料集

| 教材 | 樣本數 | FASTQ 數 | 定序模式 | 輸入位置 | 輸出位置 |
| :--- | ---: | ---: | :--- | :--- | :--- |
| **Moving Pictures（預設）** | 34 | 34 | Single-end | `01_data/` | `results/` |
| **Gut-to-Soil（Tutorial 4，選修）** | 104 | 208 | Paired-end | `examples/gut-to-soil/data/` | `results/gut-to-soil/` |

- Moving Pictures 的 34 個 FASTQ 已納入 repository，clone 後即可使用。
- Gut-to-Soil FASTQ 不納入 Git；執行
  `bash examples/gut-to-soil/download_data.sh` 下載並驗證固定 SHA-256。
- Tutorial 4 使用獨立的 data、logs、work 與 results 路徑，不會覆寫
  Moving Pictures 主教材。

### Nano4 先備條件

- 可登入 Nano4，並在 `/work/$USER` 擁有足夠空間。
- 已取得明確授權的 `<PROJECT_ID>`；每次提交前都要即時執行
  account／partition preflight。
- `GOV115088` 是生醫專用計畫，只能搭配明確允許它的 live `ngs*`
  partition；一般 GPU partition 必須使用已授權的一般 wallet project。
- 不要把個人 project ID 寫入版本控制；以
  `sbatch --account="<PROJECT_ID>"` 在提交時指定。
- 登入節點需可使用 Git、Bash、Python 3 與 `uv`。Tutorial 4 另需
  `curl`、`unzip`、`sha256sum` 與 `gzip`。

### 建議學習路徑

| 使用者 | 建議順序 |
| :--- | :--- |
| 免 Clone 零前置體驗 | Tutorial 0 (獨立入門、免 Clone、免 Skill) |
| 第一次操作（自建資產） | Tutorial 0 → Tutorial 1 → Tutorial 2 (手動) 或 Tutorial 3 (AI) |
| 使用 HPC 系統預建模組（推薦） | Tutorial 0 → Tutorial 1 → Tutorial 6 (手動) 或 Tutorial 7 (AI) |
| 定序數據品質控管 (QC) | Tutorial 5 (Slurm 批次 FastQC / MultiQC) |
| Paired-end 進階練習 | 完成主教材後進行 Tutorial 4 (Gut-to-Soil) |
| 授課教師 | 先閱讀 `course_syllabus.md`，再依 Tutorial 0–7 安排實作 |

---

## 📂 目錄結構說明

專案採用清晰的「功能導向」三層式目錄設計：

```text
nf-core-ampliseq/
├── 📄 README.md             # 🎓 教學逐步操作指南文件 (本檔案)
├── 📄 course_syllabus.md    # 教師用課程綱要
├── 📄 nextflow.config       # Nextflow 本機執行器與 Singularity 設定
├── 📂 01_data/              # 樣品資料 (定序檔 FASTQ, samplesheet, metadata)
├── 📂 02_config/            # HPC 與 Singularity 容器配置
├── 📂 03_scripts/           # Slurm 批次作業腳本 & AI 提示詞範本
├── 📂 04_viewer/            # 成果報告整合型 Web 儀表板 + 分析結果報告
├── 📂 examples/             # Gut-to-Soil 選修資料與隔離腳本
└── 📂 .agents/              # Nano4 Slurm 與 ampliseq AI Agent 技能
```

### 詳細檔案目錄說明：
- [01_data/](01_data/)
  - `fastq/`：34 筆測試樣品之單端 FASTQ 定序數據 (`.fastq.gz`)
  - `samplesheet.template.tsv`：可攜式樣品清單範本
  - `samplesheet.tsv`：由 `prepare_samplesheet.sh` 依 clone 位置產生，不納入 Git
  - `metadata.tsv`：實驗分組與環境因子數據表（標題欄第一欄需為 `sampleID`）
- [02_config/](02_config/)
  - `setup_environment.sh`：HPC 環境模組載入與 Singularity 快取路徑設定（自建資產模式）
  - `setup_environment_modules.sh`：HPC 官方預建系統模組環境載入與檢查（系統模組模式）
  - `nextflow_singularity.config`：Singularity 掛載設定樣板（含 `-B /tmp:/tmp` 修復）
- [03_scripts/](03_scripts/)
  - `prepare_samplesheet.sh`：依目前 clone 位置產生包含 FASTQ 絕對路徑的 `samplesheet.tsv`
  - `prepare_assets.sh`：在登入節點預先下載 Pipeline、Singularity images 與 SILVA 參考資料
  - `submit_ampliseq.slurm`：Slurm 提交 bash 腳本（自建資產模式）
  - `submit_ampliseq_module.slurm`：Slurm 提交 bash 腳本（系統官方模組模式）
  - `agent_prompts_example.md`：給 AI Agent 下達自動化指令的 Prompt 提示詞庫
  - `phyloseq_analysis.R`：R 下游分析範例腳本（phyloseq + PCoA）
- [04_viewer/](04_viewer/)
  - `index.html`：整合型玻璃擬態儀表板，分析完成後一頁切換瀏覽所有報告
  - `report.md`：分析結果示範報告（教師參考，學生執行後 AI 自動生成）
- `examples/gut-to-soil/`
  - `download_data.sh`：下載、驗證並準備 104 組 paired-end 選修資料
  - `data/`：與主教材隔離的 metadata、samplesheet 與 FASTQ 位置
  - `submit_ampliseq.slurm`：使用獨立 log、work 與 results 的提交腳本

### 補充教學文件

- [tutorial_0_hpc_slurm_standalone_quickstart.md](tutorial_0_hpc_slurm_standalone_quickstart.md)：零門檻獨立入門指南 (無須 Git Clone、免 Skill，含通用 Prompt 提示詞與 Markdown 報告輸出)。
- [tutorial_1_hpc_slurm_ai_quickstart.md](tutorial_1_hpc_slurm_ai_quickstart.md)：Nano4、wallet、partition 與第一個 Slurm 作業。
- [tutorial_2_16S_manual_guide.md](tutorial_2_16S_manual_guide.md)：Moving Pictures 單端資料的完整手動流程（使用者下載資產與快取）。
- [tutorial_3_16S_ai_prompt_guide.md](tutorial_3_16S_ai_prompt_guide.md)：Moving Pictures 分析的 AI Agent 提示詞與結果解讀。
- [tutorial_4_gut_to_soil_optional.md](tutorial_4_gut_to_soil_optional.md)：選修的 Gut-to-Soil paired-end 練習，使用隔離的資料與輸出目錄。
- [tutorial_5_slurm_fastq_qc.md](tutorial_5_slurm_fastq_qc.md)：Slurm 批次 FastQC / MultiQC 數據品質控管。
- [tutorial_6_modules_16S_manual_guide.md](tutorial_6_modules_16S_manual_guide.md)：使用 HPC 系統官方模組 (`biology/qiime2/2026.7` & `biology/nf-core-ampliseq/2.18.0`) 的 16S 手動流程。
- [tutorial_7_modules_16S_ai_prompt_guide.md](tutorial_7_modules_16S_ai_prompt_guide.md)：使用 HPC 系統官方模組的 AI Agent 提示詞與結果解讀指南。
- [course_syllabus.md](course_syllabus.md)：教師用課程目標、學習成果與教學安排。

---

## 🚀 逐步操作指南 (Step-by-Step Tutorial)

---

### 步驟零：Clone 課程 Repository 並進入本專案

> 這是學生**第一步**要做的事，確保在正確的目錄下操作。
> 若要重新開始完整練習，建議 clone 到新的目錄，不要刪除舊練習的
> `work/` 或 `results/`。

```bash
# 1. 在自己的工作空間 clone 本專案 repository
cd "/work/$USER"
git clone https://github.com/gemini960114/nf-core-ampliseq.git

# 2. 進入本專案目錄（所有後續指令都在此目錄下執行）
cd nf-core-ampliseq

# 3. 依目前 clone 位置重建 samplesheet 內的 FASTQ 絕對路徑
bash 03_scripts/prepare_samplesheet.sh

# 4. 確保 Slurm 日誌目錄存在
mkdir -p logs

# 5. 確認目錄結構正確
ls -la
```

若同名目錄已存在，可建立全新的練習 clone：

```bash
git clone https://github.com/gemini960114/nf-core-ampliseq.git \
  nf-core-ampliseq-practice
cd nf-core-ampliseq-practice
bash 03_scripts/prepare_samplesheet.sh
mkdir -p logs
```

**預期看到**：
```text
README.md   nextflow.config   01_data/   02_config/   03_scripts/   04_viewer/   logs/   .agents/
```

---

### 步驟一：數據與元數據準備 (`01_data/`)

1. **確認 Samplesheet 格式** (`samplesheet.tsv`)：
   - **單端 (Single-end)** 欄位：`sample\tfastq_1`
2. **確認 Metadata 格式** (`metadata.tsv`)：
   - 第一欄標頭必須為 `sampleID`。
   - 欄位名稱中的連字號 `-` 請轉為底線 `_`（例如：`body_site`）。

```bash
# 快速確認 samplesheet 欄位
head -3 01_data/samplesheet.tsv

# 快速確認 metadata 欄位名稱
head -1 01_data/metadata.tsv
```

---

### 步驟二：在登入節點準備 Pipeline、容器與參考資料

> 若使用 **AI Agent（推薦）**，步驟二可由 AI 自動完成。每位使用者第一次執行時需要網路；完成後會重用個人 cache。

#### 2.1 環境與 `uv` 安裝檢查
`prepare_assets.sh` 需使用 `uv` 工具（用於固定 `nf-core==4.0.3` 工具版本）。若你的系統尚未安裝 `uv`，請在登入節點執行以下指令安裝：
> **說明**：安裝腳本預設會將 `uv` 放置於家目錄 `~/.local/bin/uv` 並寫入 `~/.bashrc`。安裝後請執行 `source ~/.bashrc`（或加入 `export PATH="$HOME/.local/bin:$PATH"`）以確保當前 Shell 能直接識別 `uv` 指令。

```bash
# 若尚未安裝 uv，請執行：
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

#### 2.2 準備資產

每位使用者都應在登入節點執行準備腳本；資產會存入目前帳號自己的 `/work/${USER}/` 目錄。

```bash
module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7

export NXF_SINGULARITY_CACHEDIR="/work/${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3"
bash 03_scripts/prepare_assets.sh
```

> **為什麼需要這些設定？**
> - `runOptions = '-B /tmp:/tmp'`：修復 QIIME 2 Python 3.12 暫存目錄隔離問題
> - `executor = 'local'`：防止 Nextflow 在節點內再次送出 `sbatch`，導致 NCHC `No project ID` 錯誤
> - `uv tool run --from nf-core==4.0.3 nf-core pipelines download`：固定 nf-core/tools 版本，在登入節點預先下載 Pipeline 與全部 Singularity images
> - 版本化 Singularity cache：避免不同 nf-core/tools 命名規則讓相同映像重複下載；既有有效 `.img` 會以符號連結重用
> - `--ref_taxonomy_storage`：讓計算工作直接使用預先下載的 SILVA 138.2，不必在計算節點連網

個人資產會放在：

```text
/work/$USER/nf-core_download/ampliseq-2.18.0/
/work/$USER/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3/
/work/$USER/reference_databases/ampliseq/silva-138.2/
```

---

### 步驟三：彈性計算資源與 Slurm 任務派送 (`03_scripts/`)

#### ⚡ 計算資源與物種資料庫彈性設定說明
AI Agent 會以 `nano4-slurm-operations` 驗證計畫與 partition，再以
`slurm-ampliseq-guide` 準備 Moving Pictures 分析：
- **Slurm 分割區 (Partition)**：本範例預設 `ngs62g`；替換 partition 前必須重新執行即時 preflight，不使用文件中的靜態清單推測權限。
- **CPU & 記憶體**：可指定 `--cpus-per-task=32 --mem=250G`，或依數據規模調整為 16 核 / 64G 等。
- **物種資料庫 (--dada_ref_taxonomy)**：
  - 16S 細菌：`silva=138.2` (預設)
  - 真菌 ITS：`unite-fungi=9.0`（僅限替換成 ITS 輸入資料後使用）
  - 真核 18S：`pr2=5.0.0`（僅限替換成 18S 輸入資料後使用）
- **Pipeline 來源**：預設使用步驟二下載的 ampliseq 2.18.0；若放在其他位置，可在提交前設定 `AMPLISEQ_PIPELINE`：
  ```bash
  export AMPLISEQ_PIPELINE="/path/to/ampliseq/2_18_0"
  ```

#### 方式 A：由 AI Agent 一鍵自動化執行（推薦）

直接對 AI Agent 下達以下自然語言指令（Agent 會先驗證 Nano4 帳號與
partition policy，再準備並提交 ampliseq）：

> **AI 提示詞範例（複製貼上給 AI）**：
> ```
> 請先使用 nano4-slurm-operations 完成 read-only preflight，再使用 slurm-ampliseq-guide，幫我在 ngs62g 分割區派送 Moving Pictures 16S 單端分析任務。
> 我的 Slurm 計畫代碼是 <PROJECT_ID>。
> 輸入目錄為目前專案下的 01_data/；請先以 pwd 取得專案絕對路徑，並確認 samplesheet.tsv 內的 FASTQ 皆為有效絕對路徑。
> 請驗證 nextflow.config、在登入節點使用 uv 預先準備 ampliseq 2.18.0、Singularity images 與 SILVA 138.2，再生成 Slurm 腳本、提交 sbatch 並在背景監控進度。
> 完成後告訴我 MultiQC 網頁總報告與成果連結。
> ```

#### 方式 B：手動派送 Slurm 批次檔

先把 `<PROJECT_ID>` 換成自己的 Slurm 計畫代碼，再於專案根目錄執行：
```bash
bash 03_scripts/prepare_samplesheet.sh
mkdir -p logs

module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7
bash 03_scripts/prepare_assets.sh

export SLURM_ACCOUNT="<PROJECT_ID>"
bash .agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh \
  --project "$SLURM_ACCOUNT" --partition "ngs62g"
sbatch --account="$SLURM_ACCOUNT" 03_scripts/submit_ampliseq.slurm
```
並透過 `squeue -u $USER` 查詢工作進度。

---

### 步驟四：分析總結報告與全樣本數據整合 (`results/`)

當 Nextflow 分析流程順利完成後，可由 AI Agent 自動讀取並彙整 `results/` 目錄下的序列統計與多樣性數據，生成結構化的分析總結報告與全樣本數據總表。

#### 💡 由 AI Agent 自動生成總結報告與數據表（推薦）

直接對 AI Agent 下達以下自然語言指令：

> **AI 提示詞範例（複製貼上給 AI）**：
> ```
> 請根據 results/ 資料夾內的分析結果（包含 overall_summary.tsv、DADA2 去噪數據與 QIIME 2 物種分類結果），幫我撰寫一份完整的分析總結與分析結果報告 results/report.md，並確認已在 results/ 目錄下整理並放置全樣本數據總表 (results/overall_summary.tsv)。
> ```

#### 📄 核心產出檔案說明

1. **分析總結與分析結果報告 (`results/report.md`)**：
   - **數據品質與讀段統計**：彙整各處理階段（Input, Filtered, Denoised, Non-chimeric, Tax Filtered）的數據過濾品質與 DADA2 讀段保留率。
   - **多樣性與菌相組成**：摘要 Alpha / Beta 多樣性統計檢定結果，並分析不同生理採樣部位（腸道 Gut、舌頭 Tongue、手掌 Palm）的特徵菌群與門/屬 (Phylum/Genus) 階層之相對豐度差異。
2. **全樣本數據總表 (`results/overall_summary.tsv`)**：
   - 整合所有樣品在 FASTQ Input、Filtered、Denoised、Non-chimeric 及 Tax Filtered 等各階段的讀段數量與百分比數值總表，方便後續匯入 Excel 或 R 進行統計繪圖。

---

## 📊 產出報告與成果可視化

分析成功完成後，會在專案目錄下生成 `results/` 目錄，包含：

> `results/` 不包含在剛 clone 的 repository 中。下列路徑必須在 pipeline
> 成功完成後才會存在；實際 ASV 數量、執行時間、菌相比例與統計值會隨
> pipeline 版本、參數及輸入資料而變動。

1. **MultiQC 綜合統計總報告**：`results/multiqc/multiqc_report.html`
2. **流程總覽簡報**：`results/summary_report/summary_report.html`
3. **QIIME 2 互動式可視化圖表**：
   - **Taxonomy 物種分類柱狀圖**：`results/qiime2/barplot/index.html`
   - **Alpha 多樣性稀疏曲線**：`results/qiime2/alpha-rarefaction/index.html`
   - **Beta 多樣性 PCoA 3D Emperor 圖表**：`results/qiime2/diversity/beta_diversity/bray_curtis_pcoa_results-PCoA/index.html`
4. **Nextflow 執行報告（資源用量）**：`results/pipeline_info/execution_report_*.html`
5. **Nextflow Pipeline DAG 圖**：`results/pipeline_info/pipeline_dag_*.html`

### 🌐 整合型互動儀表板（推薦！）

分析完成後啟動 Web Server，即可透過單一頁面切換瀏覽所有報告：

先在自己的電腦建立 SSH tunnel：

```bash
ssh -L 8000:localhost:8000 <ACCOUNT>@<HPC_LOGIN_HOST>
```

接著在這個 SSH 連線中的專案根目錄啟動 Web Server：

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory .
```

最後在自己電腦的瀏覽器開啟：

```text
http://localhost:8000/04_viewer/index.html
```

> 儀表板 [`04_viewer/index.html`](04_viewer/index.html) 整合了 MultiQC、Pipeline 摘要、QIIME 2 物種長條圖、Alpha 稀疏曲線、3D Beta PCoA 圖表，以及 `report.md` 動態渲染與 TSV 數據表格，**不需要離開瀏覽器**即可完成全流程成果解讀。

---

## 📁 分析完成後的完整成果目錄結構

```text
results/
├── 📊 multiqc/
│   └── multiqc_report.html            # ⭐ MultiQC 綜合統計總報告
├── 📈 summary_report/
│   └── summary_report.html            # ⭐ Pipeline 全流程摘要圖表報告
├── 🔬 dada2/
│   ├── ASV_seqs.fasta                 # 本次執行產生的去噪 ASV 序列
│   ├── ASV_table.tsv                  # ASV 數量豐度矩陣
│   ├── ASV_tax.silva_138_2.tsv        # Silva 138.2 物種分類註釋（屬層級）
│   ├── ASV_tax_species.silva_138_2.tsv# 物種層級精細分類結果
│   ├── DADA2_stats.tsv                # 樣本去噪前後序列讀數統計
│   └── QC/                            # DADA2 品質圖（誤差學習曲線）
├── 🧬 qiime2/
│   ├── barplot/                       # 🌈 物種組成互動式柱狀圖
│   ├── alpha-rarefaction/             # 📉 Alpha 稀疏曲線
│   ├── abundance_tables/              # 各分類層級豐度絕對表
│   ├── rel_abundance_tables/          # 各分類層級相對豐度表（Level 2~6）
│   ├── diversity/
│   │   ├── alpha_diversity/           # Shannon / Faith PD / Observed ASVs
│   │   └── beta_diversity/            # UniFrac / Bray-Curtis PCoA + Adonis
│   └── phylogenetic_tree/             # 系統發育樹 (Rooted MAFFT + FastTree)
├── 🌊 barrnap/                        # rRNA barrnap 偵測結果
├── 🌳 treesummarizedexperiment/       # TreeSE 物件（R 後續分析用）
├── 📋 overall_summary.tsv             # ⭐ 全樣本序列過濾統計總表
├── 📝 report.md                       # ⭐ AI 自動生成之分析總結與結果報告
└── pipeline_info/
    ├── execution_report_*.html        # Nextflow 資源用量報告
    ├── execution_timeline_*.html      # 任務執行時間軸
    └── pipeline_dag_*.html            # Pipeline 有向無環圖 (DAG)
```

---

## 🔧 常見問題排查與注意事項 (Troubleshooting)

| 問題現象 | 原因 | 解決方式 |
| :--- | :--- | :--- |
| `sbatch: error: Invalid account` | 使用了錯誤或沒有權限的 Slurm 計畫代碼 | 以 `sbatch --account="<PROJECT_ID>" ...` 指定自己的有效計畫代碼 |
| `sbatch: error: No project ID was assigned` | 未指定計畫代碼，或 Nextflow 內部子任務再次提交 sbatch | 確認 `--account`，並確保 `nextflow.config` 設定 `process { executor = 'local' }` |
| QIIME 2 錯誤 `rachis` / 暫存檔失敗 | Python 3.12 暫存目錄隔離問題 | 確保 `singularity.runOptions = '-B /tmp:/tmp'` |
| Barrnap WARN: 未偵測到 rRNA | 16S V4 擴增子片段太短 (120bp)，正常現象 | 可加入 `--skip_barrnap` 跳過此步驟 |
| Slurm Job 狀態 `PD (Resources)` 等待過久 | `ngs62g` 節點資源繁忙 | 先查看 `squeue -p ngs62g`；如要更換 partition，重新執行 account/partition preflight |
| Metadata 欄位名含 `-` 導致 QIIME 2 錯誤 | QIIME 2 不允許欄位名稱含連字號 | 將欄位名稱改為底線 `_`（如 `body-site` → `body_site`）|

---

## 🧪 步驟五（選修）：R 下游進階分析 (Downstream Analysis with phyloseq)

分析完成後，可使用已快取的 Singularity `phyloseq` 容器直接執行 R 下游統計與繪圖腳本：

```bash
# 載入 Singularity 模組並使用容器執行 Rscript
module load singularity/4.3.7
singularity exec /work/${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3/quay.io-bioconductor-phyloseq-1.50.0--r44hdfd78af_0.img Rscript 03_scripts/phyloseq_analysis.R

# （可選）在 Shell 設定快捷別名：
alias Rscript="singularity exec /work/\${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3/quay.io-bioconductor-phyloseq-1.50.0--r44hdfd78af_0.img Rscript"
Rscript 03_scripts/phyloseq_analysis.R
```

範例腳本 [`03_scripts/phyloseq_analysis.R`](03_scripts/phyloseq_analysis.R) 示範了：
- 以 `dada2/ASV_table.tsv` 與 `dada2/ASV_tax.silva_138_2.tsv` 建立 phyloseq 物件。
- 繪製各採樣部位 Phylum 層級物種豐度長條圖（輸出至 `results/phyloseq_phylum_bar.png`）。
- 計算 Bray-Curtis 距離矩陣並繪製 PCoA 降維散佈圖（輸出至 `results/phyloseq_pcoa_bray.png`）。

---

## 🔁 斷點續跑 (-resume) 說明

若分析中途失敗（如記憶體不足、節點掉線），Nextflow 支援無縫斷點續算：

```bash
# 在 submit_ampliseq.slurm 中，nextflow run 命令已包含 -resume
nextflow run "/work/${USER}/nf-core_download/ampliseq-2.18.0/2_18_0" \
   -profile singularity \
   ...
   -resume   # ← 直接重跑，Nextflow 自動略過已完成步驟
```

重新提交後，Nextflow 將從快取（`work/` 目錄）恢復，**僅重新計算失敗的 task**，大幅節省時間。



---

## ❓ 學生常用自然語言 Q&A 問答集 (Natural Language Prompt & QA Examples)

本專案支援學生在分析前、中、後以自然語言對 AI Agent 進行提問。以下整理真實實作對話與推薦的問答範例，學生可複製並修改範例提示詞對 AI 發問：

> 本節出現的 `772 ASVs`、執行時間、菌相比例及 PERMANOVA 數值是既有
> Moving Pictures **參考執行結果**，不是每次執行必須完全相同的驗收值。
> 學生應以自己 `results/` 中的實際輸出進行解讀。

### 1. 任務派送與自動化執行 (Task Submission & Automation)
- 🎓 **學生提問範例**：
  > 「請先以 `nano4-slurm-operations` 驗證我的 `<PROJECT_ID>` 與 `ngs62g`，再以 `slurm-ampliseq-guide` 派送 repository 內建的 34 個 Moving Pictures 單端樣本。請驗證輸入、準備登入節點資產、提交 sbatch 並以非輪詢方式監控；完成後告訴我 MultiQC 與成果連結。」
- 💡 **AI 處理與回答摘要**：
  - 自動檢查 `samplesheet.tsv` 與 `metadata.tsv` 格式。
  - 驗證 `submit_ampliseq.slurm` 與 `nextflow.config`（包含 `-B /tmp:/tmp` 與 `process.executor = 'local'`）。
  - 提交 Slurm Job 並透過非輪詢計時器監控，完成後回報
    `results/multiqc/multiqc_report.html`。此檔案在 pipeline 完成後才會產生。

---

### 2. 生成結構化分析報告 (Report Generation)
- 🎓 **學生提問範例**：
  > 「寫一份總結報告說明分析的輸入資料、過程與結果，輸出為 `report.md`。」
- 💡 **AI 處理與回答摘要**：
  - 自動讀取 `overall_summary.tsv` 與 QIIME 2 / DADA2 統計結果。
  - 整理輸入資料規格、Pipeline 步驟、772 個 ASVs 產出量、DADA2 剪裁長度及多樣性檢定結果，寫入 [`04_viewer/report.md`](04_viewer/report.md)。

---

### 3. 開啟整合型互動網頁儀表板 (Integrated Web Dashboard & HTML Viewer)
- 🎓 **學生提問範例**：
  > 「我要看這些 HTML 報告，請幫我開啟一個整合網頁儀表板 HTML 檢視器。」
- 💡 **AI 處理與回答摘要**：
  - 建立極致視覺化、現代玻璃擬態 (Glassmorphism) 暗黑風格的整合儀表板 [`04_viewer/index.html`](04_viewer/index.html)。
  - 整合頁頂關鍵數據卡片 (772 ASVs、27m19s、PERMANOVA $p=0.001$)、側邊欄分類導航與 Marked.js Markdown / TSV 表格渲染器。
  - 透過 SSH port forwarding 連線至背景 Python HTTP 服務器，學生開啟 `http://localhost:8000/04_viewer/index.html`，即可在單一頁面切換瀏覽 MultiQC 總報告、Pipeline 摘要簡報、QIIME 2 物種柱狀圖、Alpha 稀疏曲線、Beta 多樣性 3D Emperor PCoA 圖表及 `04_viewer/report.md`。


---

### 4. 物種分類與菌相組成查詢 (Taxonomy Analysis & Abundance Query)
- 🎓 **學生提問範例**：
  > 「Taxonomy 有分析嗎？請幫我分析全樣本與不同採樣部位 (Gut, Tongue, Palm) 的主要優勢菌門與菌屬。」
- 💡 **AI 處理與回答摘要**：
  - 解析 Level 2 (門) 與 Level 6 (屬) 相對豐度數據表：
    - **門層級 (Phylum)**：Bacillota (31.98%)、Pseudomonadota (26.44%)、Bacteroidota (26.41%)。
    - **腸道 (Gut)**：*Bacteroides* 擬桿菌屬 (56.2%) 占絕對主導。
    - **舌頭 (Tongue)**：*Neisseria* 奈瑟氏菌屬 (22.1%) 與 *Haemophilus* 嗜血桿菌屬 (19.3%)。
    - **手掌 (Palm)**：*Streptococcus* 鏈球菌屬 (13.3%) 與 *Corynebacterium* 棒狀桿菌屬 (9.6%)。

---

### 5. 群聚差異與 Beta 多樣性統計分析 (Beta Diversity & PERMANOVA Stats)
- 🎓 **學生提問範例**：
  > 「請幫我分析 Beta 多樣性的統計結果，身體不同採樣部位 (`body_site`) 的菌群結構差異顯著嗎？」
- 💡 **AI 處理與回答摘要**：
  - 讀取 PERMANOVA / Adonis 統計表：
    - **Weighted UniFrac**：$R^2 = 0.615, F = 15.95, p = 0.001$（極顯著，$p < 0.001$）。
    - 解釋採樣部位能解釋高達 **61.5%** 的菌相異質性。

---

### 6. 臨床與環境因子影響評估 (Metadata Factor Analysis)
- 🎓 **學生提問範例**：
  > 「Metadata 中的 `reported_antibiotic_usage` (抗生素使用紀錄) 對腸道與皮膚菌相是否有造成顯著影響？」
- 💡 **AI 處理與回答摘要**：
  - 引導學生檢視 `diversity/beta_diversity/adonis/` 中對應因子的 Adonis 檢定表與 α-多樣性（Shannon / Faith PD）向量變化。

---

### 7. 匯出二次分析檔案 (Export Data for R / Phyloseq / Downstream Analysis)
- 🎓 **學生提問範例**：
  > 「請告訴我最終輸出的 ASV 數量表與物種註釋檔在哪裡？我想用 R / Phyloseq 進行自訂繪圖。」
- 💡 **AI 處理與回答摘要**：
  - 說明核心二次分析檔案位置：
    - ASV 數量表：`results/dada2/ASV_table.tsv`
    - 物種註釋表：`results/dada2/ASV_tax.silva_138_2.tsv`
    - QIIME 2 導出檔：`results/qiime2/abundance_tables/feature-table.tsv`

---

### 8. 計畫授權與 Partition 相容性確認 (Project Authorization & Partition Verification)
- 🎓 **學生提問範例**：
  > 「請問計畫 GOV115088 可以使用下列哪些 Partition？再麻煩幫忙確認，謝謝！
  > `ngs8g` / `ngs16g` / `ngs32g` / `ngs62g` / `ngs125g`」
- 💡 **AI 處理與回答摘要**：
  - 執行 `scontrol show partition` 檢查各 Partition 的 `AllowAccounts` 政策與 Slurm association。
  - **結論與相容性對照表**：
    | Partition 名稱 | 是否能使用 (GOV115088) | 允許使用之專案計畫 (AllowAccounts) |
    | :--- | :--- | :--- |
    | `ngs62g` | ✅ 可用 | `mst109178`, `gov108018`, `gov115088` |
    | `ngs8g` | ❌ 不可用 | `mst109178`, `gov108018` |
    | `ngs16g` | ❌ 不可用 | `mst109178`, `gov108018` |
    | `ngs32g` | ❌ 不可用 | `mst109178`, `gov108018` |
    | `ngs125g` | ❌ 不可用 | `mst109178`, `gov108018` |
  - 目前計畫 `GOV115088` 僅能在上述清單中使用 `ngs62g`，無法使用 `ngs8g`、`ngs16g`、`ngs32g` 或 `ngs125g`。
