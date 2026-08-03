# 16S 微生物菌群擴增子分析綜合報告 (Microbiome Amplicon Analysis Report)

本報告針對 Moving Pictures 數據集之 34 個單端 16S rRNA V4 區域擴增子定序數據，基於 **nf-core/ampliseq (v2.18.0)** 生物資訊分析流程與 **SILVA 138.2** 物種分類數據庫進行深入分析與綜合評估。

---

## 1. 執行摘要 (Executive Summary)

本分析成功完成了對來自 2 位受試者（subject-1 與 subject-2）在不同時間點採集自 4 個生理部位 (腸道 `gut`、左手掌 `left palm`、右手掌 `right palm`、舌頭 `tongue`) 之 34 個樣本的全套 16S 菌群分析。

### 核心成果指標
- **總測序原始讀段數 (Total Raw Input Reads)**: **263,878**
- **DADA2 去噪與去嵌合體讀段數 (Non-chimeric Reads)**: **153,874** (保留率 **58.31%**)
- **最終物種過濾後保留讀段數 (Taxonomy Filtered Reads)**: **151,547** (保留率 **57.43%**)
- **識別之擴增子序列變異株總數 (Total ASVs)**: **740** 個獨立 ASVs (序列長度統一修剪為 120 bp)
- **全樣本數據總表**: 已產出至 [overall_summary.tsv](file:///work/c00cjz00/nf-core-ampliseq-demo/results/overall_summary.tsv)

---

## 2. 數據品質與讀段過濾統計 (Read Processing & Filtering Statistics)

數據處理經過 DADA2 品質修剪 (`--trunclenf 120`)、單鹼基去噪 (Denoising)、嵌合體檢測及物種分類學過濾，整體過濾品質與損耗率表現如下：

### 2.1 數據處理階段讀段變化
| 處理階段 (Processing Stage) | 讀段總數 (Reads) | 佔原始讀段比例 (%) | 說明 (Description) |
| :--- | :---: | :---: | :--- |
| **DADA2 Input** | 263,878 | 100.00% | 原始 Demultiplexed FASTQ 讀段 |
| **Filtered** | 162,811 | 61.70% | 通過 Q30 品質分數與長度修剪 |
| **Denoised** | 159,399 | 60.41% | 完成單鹼基錯誤校正與去噪 |
| **Non-chimeric** | 153,874 | 58.31% | 移除 PCR 產生的 PCR 嵌合體序列 |
| **Filtered Tax Filter (Final)** | 151,547 | 57.43% | 排除非細菌/古菌及污染特徵後之最終有效分析讀段 |

### 2.2 採樣部位讀段保留率比較
各採樣部位因微生物生物量 (Biomass) 及樣本基質差異，展現顯著的品質與讀段保留特徵：

| 採樣部位 (Body Site) | 樣本數 (n) | 原始讀段數 (Input Reads) | 最終保留讀段數 (Retained Reads) | 部位平均保留率 (%) |
| :--- | :---: | :---: | :---: | :---: |
| **腸道 (gut)** | 8 | 83,767 | 59,689 | **71.26%** |
| **舌頭 (tongue)** | 9 | 48,434 | 31,955 | **65.98%** |
| **右手掌 (right palm)** | 9 | 64,668 | 33,031 | **51.08%** |
| **左手掌 (left palm)** | 8 | 67,009 | 26,872 | **40.10%** |

> [!NOTE]
> **採樣部位品質分析**: 腸道與舌頭樣品生物量豐富，保留率高 (>65%)；雙手掌皮膚樣品受環境暴露與微生物密度較低影響，品質衰退與過濾損耗率較高 (保留率約 40%~51%)。

---

## 3. 物種組成與群落結構分析 (Taxonomic & Community Profiling)

利用 **SILVA 138.2** 數據庫分類標註，34 個樣本在門 (Phylum) 與屬 (Genus) 級別展現出極強的部位生理生態特異性。

### 3.1 門級別 (Phylum / Level 2) 組成特徵
各生理部位前五大優勢菌門之平均相對豐富度 (%)：

| 採樣部位 (Body Site) | 第 1 大優勢菌門 | 第 2 大優勢菌門 | 第 3 大優勢菌門 | 第 4 大優勢菌門 | 第 5 大優勢菌門 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **腸道 (gut)** | **Bacteroidota** (61.29%) | **Bacillota** (34.78%) | Pseudomonadota (1.70%) | Verrucomicrobiota (1.43%) | Thermodesulfobacteriota (0.72%) |
| **左手掌 (left palm)** | **Bacillota** (34.05%) | **Pseudomonadota** (33.82%) | Actinomycetota (15.62%) | Bacteroidota (9.09%) | Fusobacteriota (6.10%) |
| **右手掌 (right palm)** | **Bacillota** (33.39%) | **Pseudomonadota** (26.73%) | Bacteroidota (20.97%) | Actinomycetota (15.06%) | Fusobacteriota (2.71%) |
| **舌頭 (tongue)** | **Pseudomonadota** (41.59%) | **Bacillota** (26.24%) | Bacteroidota (16.25%) | Fusobacteriota (10.61%) | Actinomycetota (4.42%) |

### 3.2 屬級別 (Genus / Level 6) 核心物種特徵
各部位最具代表性之核心菌屬（平均相對豐富度）：

1. **腸道 (Gut Microbes)**:
   - *Bacteroides* (**56.24%**): 絕對優勢之腸道厭氧擬桿菌屬。
   - *Faecalibacterium* (**7.36%**): 重要之丁酸鹽產生菌與腸道健康指標菌。
   - *Lachnospiraceae (未分類屬)* (**3.48%**)
   - *Phascolarctobacterium* (**3.11%**)
   - *[Eubacterium] eligens group* (**3.07%**)

2. **舌頭口腔 (Tongue Microbes)**:
   - *Neisseria* (**22.13%**): 口腔黏膜優勢奈瑟氏菌屬。
   - *Haemophilus* (**19.29%**): 口腔嗜血桿菌屬。
   - *Streptococcus* (**14.71%**): 兼性厭氧鏈球菌屬。
   - *Prevotella* (**12.24%**): 普雷沃氏菌屬。
   - *Fusobacterium* (**9.93%**): 梭桿菌屬。

3. **雙手掌皮膚 (Left & Right Palm Microbes)**:
   - **左手掌**: *Streptococcus* (13.29%), *Corynebacterium* (9.64%), *Pseudomonas* (9.26%), *Staphylococcus* (6.10%), *Neisseria* (5.41%)。
   - **右手掌**: *Bacteroides* (15.01%), *Corynebacterium* (9.40%), *Streptococcus* (9.25%), *Staphylococcus* (7.46%), *Pseudomonas* (7.09%)。

---

## 4. 生態學與生物學意義討論 (Ecological Insights)

1. **嚴格棲位分化 (Strict Niche Differentiation)**:
   - **腸道**: 由 *Bacteroidota* 與 *Bacillota* 主導 (合計 >96%)，反映腸道嚴格無氧環境對專性厭氧菌之選擇壓力。
   - **口腔**: 由兼性厭氧與微需氧菌 (*Neisseria*, *Haemophilus*, *Streptococcus*) 佔據主導地位，展現典型的口腔黏膜生態特徵。
   - **皮膚**: 菌群結構多樣化且富含耐乾悍與環境適應性菌門 (*Actinomycetota*, *Pseudomonadota*, *Bacillota*)，包含典型皮膚表居菌 *Corynebacterium* 與 *Staphylococcus*。

2. **手部菌群接觸動態**:
   - 右手掌檢出較高比例之 *Bacteroides* (15.01%)，反映日常生活行為（如手部與個體其他部位或環境之接觸）對皮膚表面微生物動態移殖之影響。

---

## 5. 分析結果產出檔案與報告連結 (Deliverables & Interactive Reports)

本分析計畫產出之主要數據與視覺化報告均已妥善放置於 `results/` 目錄：

| 成果項目 (Item) | 檔案路徑 / 連結 | 說明 (Description) |
| :--- | :--- | :--- |
| **全樣本數據總表** | [overall_summary.tsv](file:///work/c00cjz00/nf-core-ampliseq-demo/results/overall_summary.tsv) | 包含 34 樣本之中英文後續詮釋 metadata 與 DADA2/Taxonomy 過濾數據總表 |
| **MultiQC 綜合品質報告** | [multiqc_report.html](file:///work/c00cjz00/nf-core-ampliseq-demo/results/multiqc/multiqc_report.html) | 全流程 FastQC 與 pipelines 綜合互動式品質報告 |
| **Ampliseq 摘要報告** | [summary_report.html](file:///work/c00cjz00/nf-core-ampliseq-demo/results/summary_report/summary_report.html) | 包含物種分類層級圖形與統計向量圖表 |
| **DADA2 數據過濾表** | [DADA2_stats.tsv](file:///work/c00cjz00/nf-core-ampliseq-demo/results/dada2/DADA2_stats.tsv) | 原始 DADA2 去噪與過濾數據表 |
| **ASV 物種分類標註表** | [ASV_tax.silva_138_2.tsv](file:///work/c00cjz00/nf-core-ampliseq-demo/results/dada2/ASV_tax.silva_138_2.tsv) | SILVA 138.2 數據庫物種標註結果 |
| **QIIME 2 豐度長條圖** | [index.html](file:///work/c00cjz00/nf-core-ampliseq-demo/results/qiime2/barplot/index.html) | 各層級 (Level 1-9) 可視化物種相對豐度長條圖 |
| **系統發育樹** | [tree.nwk](file:///work/c00cjz00/nf-core-ampliseq-demo/results/qiime2/phylogenetic_tree/tree.nwk) | 基於 ASV 序列構建之發育樹 |

---
*分析完成日期: 2026-08-03*
