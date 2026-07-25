# 🧬 16S 微生物菌群擴增子分析 (nf-core/ampliseq) - HPC 與 AI 自動化實作指南

本專案提供在 **國網中心 / 台灣杉三號 (TWCC / NCHC) Slurm HPC** 環境下，結合 **AI Coding Agent** 與 **`nf-core/ampliseq` (16S 擴增子分析流程)** 的完整自動化實作範例。

---

## 📂 目錄結構說明

專案採用清晰的「功能導向」三層式目錄設計：

```text
moving_pictures_demo/
├── 📄 README.md             # 🎓 教學逐步操作指南文件 (本檔案)
├── 📄 nextflow.config       # Nextflow 本機執行器與 Singularity 設定
├── 📂 01_data/              # 樣品資料 (定序檔 FASTQ, samplesheet, metadata)
├── 📂 02_config/            # HPC 與 Singularity 容器配置
├── 📂 03_scripts/           # Slurm 批次作業腳本 & AI 提示詞範本
├── 📂 04_viewer/            # 成果報告整合型 Web 儀表板 + 分析結果報告
└── 📂 .agents/              # AI Agent 技能與自動化規範 (slurm_ampliseq_guide)
```

### 詳細檔案目錄說明：
- [01_data/](01_data/)
  - `fastq/`：34 筆測試樣品之單端 FASTQ 定序數據 (`.fastq.gz`)
  - `samplesheet.template.tsv`：可攜式樣品清單範本
  - `samplesheet.tsv`：由 `prepare_samplesheet.sh` 依 clone 位置產生，不納入 Git
  - `metadata.tsv`：實驗分組與環境因子數據表（標題欄第一欄需為 `sampleID`）
- [02_config/](02_config/)
  - `setup_environment.sh`：HPC 環境模組載入與 Singularity 快取路徑設定
  - `nextflow_singularity.config`：Singularity 掛載設定樣板（含 `-B /tmp:/tmp` 修復）
- [03_scripts/](03_scripts/)
  - `prepare_assets.sh`：在登入節點預先下載 Pipeline、Singularity images 與 SILVA 參考資料
  - `submit_ampliseq.slurm`：Slurm 提交 bash 腳本
  - `agent_prompts_example.md`：給 AI Agent 下達自動化指令的 Prompt 提示詞庫
  - `phyloseq_analysis.R`：R 下游分析範例腳本（phyloseq + PCoA）
- [04_viewer/](04_viewer/)
  - `index.html`：整合型玻璃擬態儀表板，分析完成後一頁切換瀏覽所有報告
  - `viewer.html`：輕量 HTML 報告入口
  - `report.md`：分析結果示範報告（教師參考，學生執行後 AI 自動生成）

---

## 🚀 逐步操作指南 (Step-by-Step Tutorial)

---

### 步驟零：Clone 課程 Repository 並進入本專案

> 這是學生**第一步**要做的事，確保在正確的目錄下操作。

```bash
# 1. 在自己的工作空間 clone 整份課程 repository
cd "/work/$USER"
git clone https://github.com/gemini960114/hpc-course.git

# 2. 進入本專案子目錄（所有後續指令都在此目錄下執行）
cd hpc-course/moving_pictures_demo

# 3. 依目前 clone 位置重建 samplesheet 內的 FASTQ 絕對路徑
bash 03_scripts/prepare_samplesheet.sh

# 4. 確保 Slurm 日誌目錄存在
mkdir -p logs

# 5. 確認目錄結構正確
ls -la
```

**預期看到**：
```text
README.md   nextflow.config   01_data/   02_config/   03_scripts/   04_viewer/   logs/   .agents/
```

---

### 步驟一：數據與元數據準備 (`01_data/`)

1. **確認 Samplesheet 格式** (`samplesheet.tsv`)：
   - **單端 (Single-end)** 欄位：`sample\tfastq_1`
   - **雙端 (Paired-end)** 欄位：`sample\tfastq_1\tfastq_2`
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

```bash
# 確認已安裝 uv
uv --version

# 一次準備 ampliseq 2.18.0、Singularity images 與 SILVA 138.2
bash 03_scripts/prepare_assets.sh

# 確認專案設定
test -f nextflow.config
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
AI Agent (`slurm_ampliseq_guide`) 支援根據需求彈性調整以下設定：
- **Slurm 分割區 (Partition)**：預設 `ngs250g` (高記憶體)，可彈性切換為 `ngs96g`、`ct96`、`ct180` 等。
- **CPU & 記憶體**：可指定 `--cpus-per-task=32 --mem=250G`，或依數據規模調整為 16 核 / 64G 等。
- **物種資料庫 (--dada_ref_taxonomy)**：
  - 16S 細菌：`silva=138.2` (預設)
  - 真菌 ITS：`unite-fungi=9.0`
  - 真核 18S：`pr2=5.0.0`
- **Pipeline 來源**：預設使用步驟二下載的 ampliseq 2.18.0；若放在其他位置，可在提交前設定 `AMPLISEQ_PIPELINE`：
  ```bash
  export AMPLISEQ_PIPELINE="/path/to/ampliseq/2_18_0"
  ```

#### 方式 A：由 AI Agent 一鍵自動化執行（推薦）

直接對 AI Agent 下達以下自然語言指令（Agent 會自動調用 `slurm_ampliseq_guide` 技能，驗證 `nextflow.config`、準備 Pipeline、生成 Slurm 腳本、提交 `sbatch` 並進行非輪詢式背景監控）：

> **AI 提示詞範例（複製貼上給 AI）**：
> ```
> 請參考 slurm_ampliseq_guide 技能，幫我在 ngs250g 分割區派送一個 16S 擴增子分析任務。
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
sbatch --account="$SLURM_ACCOUNT" 03_scripts/submit_ampliseq.slurm
```
並透過 `squeue -u $USER` 查詢工作進度。

---

## 📊 產出報告與成果可視化

分析成功完成後，會在專案目錄下生成 `results/` 目錄，包含：

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
│   ├── ASV_seqs.fasta                 # 740 條去噪 ASV 序列（120 bp 均一）
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
| Slurm Job 狀態 `PD (Resources)` 等待過久 | `ngs250g` 節點資源繁忙 | 改用 `ngs96g`（96G RAM），或監控 `squeue -p ngs250g` |
| Metadata 欄位名含 `-` 導致 QIIME 2 錯誤 | QIIME 2 不允許欄位名稱含連字號 | 將欄位名稱改為底線 `_`（如 `body-site` → `body_site`）|

---

## 🧪 步驟四（選修）：R 下游進階分析 (Downstream Analysis with phyloseq)

分析完成後，可進一步使用 R `phyloseq` 套件進行客製化繪圖與統計分析：

```bash
# 執行 R 下游分析範例腳本
Rscript 03_scripts/phyloseq_analysis.R
```

範例腳本 [`03_scripts/phyloseq_analysis.R`](03_scripts/phyloseq_analysis.R) 示範了：
- 以 `dada2/ASV_table.tsv` 與 `dada2/ASV_tax.silva_138_2.tsv` 建立 phyloseq 物件。
- 繪製各採樣部位 Phylum 層級物種豐度長條圖。
- 計算 Bray-Curtis 距離矩陣並繪製 PCoA 降維散佈圖。

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

### 1. 任務派送與自動化執行 (Task Submission & Automation)
- 🎓 **學生提問範例**：
  > 「請參考 `slurm_ampliseq_guide` 技能，使用我的 Slurm 計畫代碼 `<PROJECT_ID>`，幫我在 `ngs250g` 分割區派送一個 16S 擴增子分析任務。輸入目錄為目前專案下的 `01_data/`；請先以 `pwd` 取得專案絕對路徑。請準備 Pipeline、生成 Slurm 腳本、提交 sbatch 並在背景監控進度。完成後告訴我 MultiQC 網頁總報告與成果連結。」
- 💡 **AI 處理與回答摘要**：
  - 自動檢查 `samplesheet.tsv` 與 `metadata.tsv` 格式。
  - 驗證 `submit_ampliseq.slurm` 與 `nextflow.config`（包含 `-B /tmp:/tmp` 與 `process.executor = 'local'`）。
  - 提交 Slurm Job 並透過非輪詢計時器監控，完成後回報 [MultiQC 報告](results/multiqc/multiqc_report.html) 連結。

---

### 2. 生成結構化分析報告 (Report Generation)
- 🎓 **學生提問範例**：
  > 「寫一份總結報告說明分析的輸入資料、過程與結果，輸出為 `report.md`。」
- 💡 **AI 處理與回答摘要**：
  - 自動讀取 `overall_summary.tsv` 與 QIIME 2 / DADA2 統計結果。
  - 整理輸入資料規格、Pipeline 步驟、740 個 ASVs 產出量、DADA2 剪裁長度及多樣性檢定結果，寫入 [`04_viewer/report.md`](04_viewer/report.md)。

---

### 3. 開啟整合型互動網頁儀表板 (Integrated Web Dashboard & HTML Viewer)
- 🎓 **學生提問範例**：
  > 「我要看這些 HTML 報告，請幫我開啟一個整合網頁儀表板 HTML 檢視器。」
- 💡 **AI 處理與回答摘要**：
  - 建立極致視覺化、現代玻璃擬態 (Glassmorphism) 暗黑風格的整合儀表板 [`04_viewer/index.html`](04_viewer/index.html)。
  - 整合頁頂關鍵數據卡片 (740 ASVs、27m28s、PERMANOVA $p=0.001$)、側邊欄分類導航與 Marked.js Markdown / TSV 表格渲染器。
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
    - **Weighted UniFrac**：$R^2 = 0.606, F = 15.38, p = 0.001$（極顯著，$p < 0.001$）。
    - 解釋採樣部位能解釋高達 **60.6%** 的菌相異質性。

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
    - ASV 數量表：[`results/dada2/ASVs_count.tsv`](results/dada2/ASVs_count.tsv)
    - 物種註釋表：[`results/dada2/ASVs_taxonomy.tsv`](results/dada2/ASVs_taxonomy.tsv)
    - QIIME 2 導出檔：[`results/qiime2/abundance_tables/feature-table.tsv`](results/qiime2/abundance_tables/feature-table.tsv)
