# 🎓 高效能計算 (HPC) 與 AI 輔助 16S 微生物體學分析實務
## 課程教學大綱 (Course Syllabus)

---

## 📌 一、 課程簡介 (Course Overview)

本課程專為生物資訊學、生醫研究人員與 HPC 終端使用者設計，旨在結合**高效能計算 (HPC Slurm)**、**Nextflow 自動化分析管線**、**Singularity 容器技術**與 **AI Agent 智慧對話輔助**，帶領學員從零建立現代化 16S rRNA 擴增子微生物體學分析實力。

學員將親自在國網中心 (NCHC) 高效能計算環境中，實作並完成從原始定序數據 (FastQ) 到 DADA2 去噪、SILVA 138.2 物種註釋、QIIME 2 生態學統計，以及 R `phyloseq` 下游視覺化繪圖的全套分析流程。

---

## 🎯 二、 學習目標 (Learning Objectives)

完成本課程後，學員將能夠：
1. **HPC 運算資源調度**：熟練掌握 Slurm 任務調度系統 (sbatch/squeue/sacct)、計畫授權與 partition preflight。
2. **分析管線自動化**：理解 Nextflow 架構與 `nf-core/ampliseq` 16S 分析模組流程。
3. **離線與容器化管理**：掌握 Singularity 容器快取佈署與環境隔離機制（如 `-B /tmp:/tmp`）。
4. **生態學統計與視覺化**：獨立完成 DADA2 去噪、Alpha/Beta 多樣性統計 (PERMANOVA/Adonis) 與 R `phyloseq` 繪圖。
5. **AI 輔助 pair-programming**：運用自然語言提示詞 (Prompt Engine) 進行 AI 智慧任務派送、監控、數據解讀與 Markdown 報告生成。

---

## 📅 三、 課程單元大綱 (Curriculum Modules)

### 🔹 單元一：HPC 環境建置與資料預處理 (HPC & Data Preparation)
- **1.1 HPC Slurm 基礎操作與權限設定**
  - 使用者空間 `/work/${USER}` 規範與專案結構建置。
  - Slurm 計畫授權與 account／partition 即時 preflight。
  - 認識 `GOV115088` 生醫計畫與一般 GPU wallet project 的使用界線。
- **1.2 16S 原始定序數據與 Metadata 對照表**
  - 檢視 Moving Pictures 的 34 個 single-end 樣本與 34 個 FASTQ。
  - 格式化 `samplesheet.tsv`（絕對路徑定義）與 `metadata.tsv`（採樣部位、抗生素紀錄、時間點）。
- **1.3 離線資產與 Singularity 容器準備**
  - 執行 `03_scripts/prepare_assets.sh` 預先下載與檢查 Singularity `.img` 映像檔完整性。

### 🔹 單元二：Nextflow 管線派送與背景監控 (Pipeline Execution & Slurm Monitoring)
- **2.1 `nf-core/ampliseq` 生物資訊原理**
  - 質量過濾 (FastQC)、DADA2 去噪 (120 bp Trim)、去嵌合體與 ASV 特徵生成。
  - 比較實際執行結果與參考結果，不把固定 ASV 數量當作驗收條件。
- **2.2 撰寫與提交 Slurm Job**
  - 解析與修訂 `03_scripts/submit_ampliseq.slurm` 腳本。
  - 使用 `sbatch` 派送作業與非輪詢 (Non-polling) 背景狀態追蹤。
- **2.3 斷點續算與障礙排除 (-resume)**
  - `work/` 快取目錄機制與 `scancel` 舊作業清理。
  - Singularity 暫存檔隔離 (`runOptions = '-B /tmp:/tmp'`) 障礙排除實務。

### 🔹 單元三：物種分類與生態學多樣性統計 (Taxonomy & Diversity Analysis)
- **3.1 SILVA 138.2 資料庫與物種分類**
  - 門層級 (Phylum: Bacillota, Pseudomonadota, Bacteroidota) 與 屬層級 (Genus: *Bacteroides*, *Neisseria*, *Corynebacterium*) 分類解析。
  - 人體微生態棲地特異性 (Niche Specificity: Gut, Tongue, Skin) 解讀。
- **3.2 QIIME 2 生物多樣性指標**
  - Alpha 多樣性 (Shannon, Faith's PD) 及 Rarefaction 抽樣曲線。
  - Beta 多樣性矩陣（Bray-Curtis, UniFrac）與 3D Emperor PCoA 降維散佈圖。
- **3.3 PERMANOVA / Adonis 變異數分析**
  - 讀取並解釋 Adonis 統計結果中的 $R^2$、$F$ 與 $p$ 值。

### 🔹 單元四：R `phyloseq` 客製化繪圖與 AI 智慧互動 (R Visualization & AI Dashboard)
- **4.1 容器化 Rscript 下游進階分析**
  - 使用快取的 `phyloseq` Singularity 容器執行 `03_scripts/phyloseq_analysis.R`。
  - 繪製並輸出 `results/phyloseq_phylum_bar.png` 與 `results/phyloseq_pcoa_bray.png`。
- **4.2 AI 輔助數據解讀與 Markdown 報告生成**
  - 以自然語言提示詞委託 AI Agent 自動撰寫 [`04_viewer/report.md`](04_viewer/report.md)。
- **4.3 互動式 HTML 檢視儀表板 (Web Dashboard)**
  - 啟動 Python HTTP 服務器 (`http://localhost:8000/04_viewer/index.html`)。
  - 透過 SSH Port Forwarding 瀏覽整合型暗黑風儀表板與 MultiQC 報告。
- **4.4 選修 paired-end 延伸練習**
  - 以 Tutorial 4 準備 104 組 Gut-to-Soil 樣本與 208 個 FASTQ。
  - 比較 single-end／paired-end samplesheet、剪裁參數與隔離輸出目錄。

---

## 📊 四、 評量方式與作業 (Evaluation & Deliverables)

| 評量項目 | 比重 | 繳交內容與說明 |
| :--- | :---: | :--- |
| **課堂實作與 Slurm 派送** | 30% | 成功完成 `03_scripts/submit_ampliseq.slurm` 派送並取得 `Pipeline completed successfully` 畫面。 |
| **R `phyloseq` 圖表繪製** | 30% | 繳交產出之 `phyloseq_phylum_bar.png` 與 `phyloseq_pcoa_bray.png` 圖表。 |
| **綜合分析報告 (`report.md`)** | 40% | 運用 AI Prompt 生成結構化 Markdown 報告，並說明自己數據中採樣部位的菌相差異與 PERMANOVA 統計結果。 |

---

## 💬 五、 附錄：推薦 AI 自然語言提示詞集 (Recommended AI Prompts)

學員可在學習過程中複製以下 Prompt 對 AI 提問：

1. **任務派送**：「請先使用 `nano4-slurm-operations` 驗證我的 `<PROJECT_ID>` 與 `ngs250g`，再使用 `slurm-ampliseq-guide` 派送 Moving Pictures 16S 分析並以非輪詢方式監控。」
2. **數據解讀**：「Taxonomy 有分析嗎？請幫我分析全樣本與不同 `body_site` 的主要優勢菌門與菌屬。」
3. **統計分析**：「請幫我分析 Beta 多樣性的統計結果，不同採樣部位 (`body_site`) 的菌群結構差異顯著嗎？」
4. **報告寫作**：「請幫我寫一份總結報告，說明這次 16S 分析的輸入資料、處理過程與統計結果，輸出至 `04_viewer/report.md`。」
5. **網頁儀表板**：「我要看這些 HTML 報告，請幫我開啟一個整合網頁儀表板 HTML 檢視器。」
