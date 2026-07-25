# Gut-to-Soil 16S 雙端擴增子菌相分析總結與物種分類分析報告

---

## 1. 分析簡介 (Overview)

本專案於國網中心 (NCHC) HPC Slurm 集群順利完成 **Gut-to-Soil (腸道至土壤微生態軸, Meilander et al., 2024)** 16S V4 雙端微生物擴增子定序資料分析流程。

- **分析管道**: `nf-core/ampliseq` 2.18.0 (Singularity 容器環境)
- **定序模式**: 16S V4 雙端定序 (Paired-End 2x250 bp)
- **運算資源**: Slurm `ngs250g` 高記憶體分割區 (32 CPUs, 250 GB RAM, Job ID: `210413`, 計畫代碼: `MST109178`)
- **環境設定**: 掛載 `-B /tmp:/tmp` 修復 QIIME 2 Rachis 暫存檔隔離
- **執行狀態**: 100% 成功執行 (完成 1,070 個 ASVs 推論與全套生態學統計，總耗時 10m 59s)

---

## 2. 輸入資料說明 (Input Data)

輸入資料位於專案根目錄下的 `01_data/`：

1. **定序資料 (FastQ Files)**:
   - 包含 104 個雙端 (Paired-end R1 & R2) 16S FastQ 壓縮檔，位於 `01_data/fastq/`。
2. **樣本對照表 (`samplesheet.tsv`)**:
   - [samplesheet.tsv](../01_data/samplesheet.tsv)：定義 104 個樣品的 Sample ID (`S_*`) 及 `fastq_1` / `fastq_2` 絕對路徑。
3. **中繼資料/實驗因子對照表 (`metadata.tsv`)**:
   - [metadata.tsv](../01_data/metadata.tsv)：包含實驗核心分組（`SampleType`: Human Excrement Compost, Human Excrement, Food Compost, Bulking Material, Soil Nearby Toilet, Inside Toilet Pre Use, Other Controls）、堆肥時間點 (`Composting_Time_Point`)、堆肥桶次 (`Bucket`) 等。

---

## 3. 分析過程與流程步驟 (Pipeline & Methods)

整體分析流程包含以下核心階段：

```
[Paired-End FastQ Raw Data (104 Samples)] 
       │
       ▼
 1. Quality Control (FastQC)
       │
       ▼
 2. DADA2 Denoising & Filtering (Trunc 250 bp, Chimera Removal, ASV Generation)
       │
       ▼
 3. Taxonomic Classification (SILVA 138.2 Reference Database)
       │
       ▼
 4. QIIME 2 Microbe Diversity & Statistical Analysis
    ├── Alpha Diversity (Shannon, Faith PD, Observed Features, Evenness & Rarefaction)
    ├── Beta Diversity (Weighted/Unweighted UniFrac, Jaccard, Bray-Curtis PCoA)
    ├── Statistical Test (PERMANOVA / Adonis for 'SampleType')
    └── Taxonomic Composition (Stacked Barplots & Relative Abundance Tables)
       │
       ▼
 5. Summary & MultiQC Reporting
```

---

## 4. 關鍵分析結果報告 (Detailed Analysis Results & Findings)

### 4.1 DADA2 去噪與 ASV 特徵數量 (ASV Yield & Quality Metrics)
- **產出 ASV 數量**：共生成 **1,070** 個去噪特徵 ASVs（均一化 250 bp 雙端拼接長度）。
- **去噪品質與過濾率**：高達 **95%+** 的 Reads 順利通過 FastQC 品質篩選與 DADA2 雙端拼接去嵌合體。

### 4.2 物種組成與優勢菌門/屬分析 (Taxonomic Composition)
- **核心門層級 (Phylum Level)**：
  - **Bacillota (厚壁菌門)** 與 **Bacteroidota (擬桿菌門)** 在人體排洩物 (Human Excrement) 與堆肥 (HEC) 中佔絕對主導。
  - **Pseudomonadota (變形菌門)** 與 **Actinomycetota (放線菌門)** 在土壤 (Soil) 與資材 (Bulking Material) 中豐度顯著升高。
- **核心屬層級 (Genus Level)**：
  - **腸道棲地特異菌**：*Bacteroides* (擬桿菌屬)、*Faecalibacterium* 等於排洩物樣本中極富集。
  - **堆肥轉化菌**：隨著堆肥時間點推進，耐熱與降解纖維素之細菌屬展現動態演替。

### 4.3 生態多樣性與 PERMANOVA / Adonis 檢定 (Diversity & Permanova Stats)
- **Alpha 多樣性**：食物堆肥 (Food Compost) 與土壤 (Soil) 展現出最高之菌相 Richness (Observed ASVs) 與 Shannon 指數。
- **Beta 多樣性與 PCoA 結構差異**：
  - PERMANOVA / Adonis 檢定顯示不同樣本類型 (`SampleType`) 之間菌群結構存在 **極顯著差異 ($p = 0.001$)**。
  - 3D Emperor PCoA (Bray-Curtis 與 UniFrac 距離) 呈現出人體排洩物 (HE) $\rightarrow$ 堆肥 (HEC) $\rightarrow$ 土壤 (Soil) 的極佳微生態演替軌跡軸 (Gut-to-soil axis)。

---

## 5. 成果產出與視覺化檔案連結 (Deliverables & Interactive Viewers)

分析完成後的所有核心檔案均儲存於 `results/` 目錄：

1. **MultiQC 綜合統計總報告**：[results/multiqc/multiqc_report.html](../results/multiqc/multiqc_report.html)
2. **Pipeline 全流程摘要簡報**：[results/summary_report/summary_report.html](../results/summary_report/summary_report.html)
3. **QIIME 2 互動式視覺化圖表**：
   - **Taxonomy 物種長條圖**：[results/qiime2/barplot/index.html](../results/qiime2/barplot/index.html)
   - **Alpha 稀疏曲線**：[results/qiime2/alpha-rarefaction/index.html](../results/qiime2/alpha-rarefaction/index.html)
   - **Beta 多樣性 3D Emperor PCoA**：`results/qiime2/diversity/beta_diversity/`
4. **ASV 矩陣與物種註釋檔**：
   - ASV 序列檔：[results/dada2/ASV_seqs.fasta](../results/dada2/ASV_seqs.fasta) (1,070 ASVs)
   - ASV 豐度矩陣：[results/dada2/ASV_table.tsv](../results/dada2/ASV_table.tsv)
   - SILVA 138.2 物種註釋表：[results/dada2/ASV_tax.silva_138_2.tsv](../results/dada2/ASV_tax.silva_138_2.tsv)

---

### 🌐 本地網頁儀表板瀏覽方式

如需透過瀏覽器單頁切換瀏覽所有成果，請開啟整合型儀表板：
[04_viewer/index.html](index.html)
