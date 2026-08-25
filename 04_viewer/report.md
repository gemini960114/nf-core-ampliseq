# 16S 擴增子菌相分析總結與物種分類分析報告 (Moving Pictures Demo)

---

## 1. 分析簡介 (Overview)

本專案參考 `slurm-ampliseq-guide` 技能規範，於國網中心 (NCHC) HPC Slurm 集群派送並順利完成 `nf-core/ampliseq` 16S 微生物擴增子定序資料分析流程。

- **分析管道**: `nf-core/ampliseq` 2.18.0 (Singularity 容器環境)
- **運算資源**: Slurm `ngs62g` 高記憶體分割區（32 CPUs、250 GB RAM；計畫代碼依使用者授權於提交時指定）
- **環境設定**: 掛載 `-B /tmp:/tmp` 防止 QIIME 2 (2026.7+) Rachis 暫存檔隔離異常
- **執行狀態**: 100% 成功執行 (共 162 個 Nextflow Task 完成，總耗時 27m 19s)

---

## 2. 輸入資料說明 (Input Data)

輸入資料位於專案根目錄下的 `01_data/`：

1. **定序資料 (FastQ Files)**:
   - 包含 34 個 Single-end 16S FastQ 壓縮檔 (`01_data/fastq/L1S8.fastq.gz` ~ `L6S93.fastq.gz`)。
2. **樣本對照表 (`samplesheet.tsv`)**:
   - [samplesheet.tsv](../01_data/samplesheet.tsv)：定義樣本 ID 與 FastQ 絕對路徑。
3. **中繼資料/臨床對照表 (`metadata.tsv`)**:
   - [metadata.tsv](../01_data/metadata.tsv)：包含採樣部位（`body_site`: gut, tongue, left palm, right palm）、受試者編號（`subject`）、抗生素使用紀錄（`reported_antibiotic_usage`）及實驗時間點。

---

## 3. 分析過程與流程步驟 (Pipeline & Methods)

整體分析流程包含以下核心階段：

```
[FastQ Raw Data]
       │
       ▼
 1. Quality Control (FastQC)
       │
       ▼
 2. DADA2 Denoising & Filtering (120 bp Trim, Chimera Removal, ASV Generation)
       │
       ▼
 3. Taxonomic Classification (Silva 138.2 Reference Database)
       │
       ▼
 4. QIIME 2 Microbe Diversity & Statistical Analysis
    ├── Alpha Diversity (Shannon, Faith PD, Observed Features, Evenness & Rarefaction)
    ├── Beta Diversity (Weighted/Unweighted UniFrac, Jaccard, Bray-Curtis PCoA)
    ├── Statistical Test (PERMANOVA / Adonis for 'body_site')
    └── Taxonomic Composition (Stacked Barplots & Relative Abundance Tables)
       │
       ▼
 5. Summary & MultiQC Reporting
```

---

## 4. 關鍵分析結果報告 (Detailed Analysis Results & Findings)

### 4.1 DADA2 去噪與 ASV 特徵數量 (ASV Yield & Quality Metrics)
- **總 ASV 數量**: 共鑑定出 **772 個 ASVs** (Amplicon Sequence Variants)。
- **序列長度**: 均一精準裁切為 **120 bp**。
- **序列保留率**: 各樣本經過濾、去噪與嵌合體剔除後，序列保留率高達 **85.30% ~ 100.00%**（詳見 [overall_summary.tsv](../results/overall_summary.tsv)）。

### 4.2 β-多樣性與 PERMANOVA (Adonis) 顯著性檢定結果
針對採樣部位（`body_site`: gut, tongue, left palm, right palm）進行群聚差異多元變異數分析（PERMANOVA / Adonis 檢定）：

| 距離矩陣 (Distance Metric) | 自由度 (Df) | F 統計量 (F-statistic) | 變異解釋分率 ($R^2$) | 顯著性檢定 ($p$-value) | 統計意義 |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Weighted UniFrac** | 3 | **15.95** | **0.615 (61.5%)** | **0.001** | **極顯著 ($p < 0.001$)** |
| **Unweighted UniFrac** | 3 | **8.74** | **0.466 (46.6%)** | **0.001** | **極顯著 ($p < 0.001$)** |
| **Bray-Curtis** | 3 | **7.35** | **0.424 (42.4%)** | **0.001** | **極顯著 ($p < 0.001$)** |
| **Jaccard** | 3 | **5.38** | **0.350 (35.0%)** | **0.001** | **極顯著 ($p < 0.001$)** |

---

### 4.3 物種分類與棲地特異性分析 (Taxonomic Composition Analysis)

基於 Silva 138.2 資料庫進行全基因體物種比對，分析結果顯示人體不同部位（gut, tongue, left palm, right palm）呈現極顯著的物種組成與優勢菌群分化：

#### 門層級 (Phylum Level) 平均相對豐度前五名
1. **Bacillota (原厚壁菌門 Firmicutes)**: **31.98%**
2. **Pseudomonadota (原變形菌門 Proteobacteria)**: **26.44%**
3. **Bacteroidota (擬桿菌門)**: **26.41%**
4. **Actinomycetota (放線菌門)**: **8.83%**
5. **Fusobacteriota (梭桿菌門)**: **4.98%**

#### 各採樣部位 (Body Site) 特異性優勢菌屬 (Genus Level)
- 💩 **腸道 (Gut)**:
  - **Bacteroides (擬桿菌屬)**: **56.2%**（絕對優勢核心腸道菌）
  - **Faecalibacterium (費氏桿菌屬)**: **7.4%**（重要丁酸產生菌）
  - **Phascolarctobacterium**: 3.1%
- 👅 **舌頭/口腔 (Tongue)**:
  - **Neisseria (奈瑟氏菌屬)**: **22.1%**
  - **Haemophilus (嗜血桿菌屬)**: **19.3%**
  - **Streptococcus (鏈球菌屬)**: **14.7%**
  - **Prevotella (普雷沃氏菌屬)**: **12.2%**
- ✋ **手掌/皮膚 (Left & Right Palm)**:
  - **Streptococcus (鏈球菌屬)**: **13.3% / 9.2%**
  - **Corynebacterium (棒狀桿菌屬)**: **9.6% / 9.4%**（經典皮膚共生菌）
  - **Pseudomonas (假單胞菌屬)**: **9.3%**
  - **Staphylococcus (葡萄球菌屬)**: **6.1% / 7.5%**（經典皮膚共生菌）

> 📌 **物種分類結論**:
> 物種分類分析結果強烈證實了微生物棲地特異性 (Niche Specificity)。腸道菌相以擬桿菌屬 (Bacteroides) 為絕對優勢，口腔/舌頭由奈瑟氏菌屬與嗜血桿菌屬主導，而手掌皮膚則顯著富集棒狀桿菌屬與葡萄球菌屬。

---

## 5. 成果檔案與報告連結 (Results & Deliverables)

| 成果項目 | 檔案類型 | 描述 / 連結 |
| :--- | :--- | :--- |
| **MultiQC 綜合網頁總報告** | HTML | [multiqc_report.html](../results/multiqc/multiqc_report.html) |
| **Nextflow 流程圖表總結報告** | HTML | [summary_report.html](../results/summary_report/summary_report.html) |
| **物種相對豐度表 (Level 2~6)** | TSV | [qiime2/rel_abundance_tables/](../results/qiime2/rel_abundance_tables/) |
| **全樣本序列統計總表** | TSV | [overall_summary.tsv](../results/overall_summary.tsv) |
| **QIIME 2 多樣性與物種長條圖** | 目錄 | [qiime2/](../results/qiime2/) |
| **DADA2 去噪與物種分類目錄** | 目錄 | [dada2/](../results/dada2/) |
| **FastQC 質檢報告目錄** | 目錄 | [fastqc/](../results/fastqc/) |

---

## 6. 腳本與環境紀錄 (Reproducibility)

- **Slurm 提交腳本**: [`03_scripts/submit_ampliseq.slurm`](../03_scripts/submit_ampliseq.slurm)
- **Nextflow 配置檔**: [`nextflow.config`](../nextflow.config)
- **執行日誌**: [`logs/job-209969.out`](../logs/job-209969.out)
