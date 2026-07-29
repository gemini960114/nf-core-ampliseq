# 🤖 16S 擴增子分析 - AI Agent Prompt 操作指南與分析後 Q&A 提示詞庫
> 本手冊提供給研究人員使用 AI Agent (如 Antigravity / Claude) 自動化派送 `nf-core/ampliseq 2.18.0` 16S 分析任務的全套 Prompts，包含**一鍵自動派送**、**分階段流程Prompt**，以及**分析完成後的數據解讀與 Q&A 提示詞庫**。

---

## 📋 Prompt 類別目錄

1. [⭐ 一鍵全自動派送 Prompt](#1-⭐-一鍵全自動派送-prompt)
2. [📥 分階段執行 Prompt 庫](#2-📥-分階段執行-prompt-庫)
3. [❓🔥 分析完成後的 Q&A 提示詞庫 (Post-Analysis QA Prompts)](#3-❓-分析完成後的-qa-提示詞庫)
   - [QA 1：QC 定序品質與 DADA2 去噪數據評估](#qa-1-qc-定序品質與-dada2-去噪數據評估)
   - [QA 2：Alpha / Beta 多樣性與 PERMANOVA (Adonis) 統計檢定解讀](#qa-2-alpha--beta-多樣性與-permanova-adonis-統計檢定解讀)
   - [QA 3：物種組成分析與群落演替優勢菌群提取](#qa-3-物種組成分析與群落演替優勢菌群提取)
   - [QA 4：執行 R 下游繪圖與 Markdown 綜合論文級報告撰寫](#qa-4-執行-r-下游繪圖與-markdown-綜合論文級報告撰寫)

---

## 1. ⭐ 一鍵全自動派送 Prompt

直接複製以下 Prompt 給 AI Agent，AI 將自動調用 `.agents/skills/slurm_ampliseq_guide` 技能並完成資料下載、校正、資產檢驗、Slurm 作出提交與背景監控：

```text
請先參考 nano4-slurm-operations 技能完成計畫與 partition preflight，再參考 slurm_ampliseq_guide 技能，幫我將 Gut-to-Soil 16S 雙端定序數據帶入本專案進行分析。
我的 Slurm 計畫代碼是 MST109178，請使用 ngs250g 分割區。

請協助執行以下步驟：
1. 從以下 URL 下載數據並放至 01_data/：
   - Metadata: https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/sample-metadata.tsv
   - Demux Artifact: https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/demux.qza
2. 將 demux.qza 解包為 FASTQ.gz 檔案放至 01_data/fastq/。
3. 將 Metadata 明確儲存為 01_data/metadata.raw.tsv，依序執行 03_scripts/prepare_gut_to_soil.py 與 03_scripts/clean_metadata.py。
4. 執行 03_scripts/prepare_samplesheet.sh 產生雙端 samplesheet.tsv（含 S_ 前綴與 fastq_1/fastq_2 絕對路徑）。
5. 驗證 03_scripts/prepare_assets.sh，確保登入節點資產已備妥。
6. 提交 sbatch 並在背景進行非輪詢式監控，完成後告訴我 MultiQC 總報告與成果連結。
```

---

## 2. 📥 分階段執行 Prompt 庫

### 階段一：數據下載與 Metadata 校正
```text
請幫我下載 Gut-to-Soil 數據集並進行標準化格式處理：
1. 下載 sample-metadata.tsv 至 01_data/metadata.raw.tsv。
2. 下載 demux.qza 並將裡面的 208 個 FASTQ.gz 檔案解包導出至 01_data/fastq/。
3. 依序執行 03_scripts/prepare_gut_to_soil.py、03_scripts/clean_metadata.py 與 03_scripts/prepare_samplesheet.sh，並確認 samplesheet 絕對路徑正確。
```

### 階段二：Slurm 任務派送與監控
```text
請幫我配置並提交 16S 雙端分析的 Slurm 批次作業：
1. 我的計畫代碼是 MST109178，請先以 nano4-slurm-operations 驗證後使用 ngs250g 分割區。
2. 確保 submit_ampliseq.slurm 設定：
   - 雙端模式 (trunclenf 250, trunclenr 250)
   - --ignore_empty_input_files (自動略過低 Reads 樣品)
   - --metadata_category_barplot "SampleType" --qiime_adonis_formula "SampleType"
3. 使用 sbatch 提交任務並啟動背景計時器追蹤進度。
```

---

## 3. ❓ 分析完成後的 Q&A 提示詞庫

作業成功執行完成後，您可以複製以下 Prompts 請 AI Agent 為您解讀實驗數據與產出報告：

### 📊 QA 1：QC 定序品質與 DADA2 去噪數據評估
```text
分析任務已完成！請幫我檢查 results/dada2/dada2_stats.tsv 與 MultiQC 報告：
1. 請統計所有樣品的原始 Reads 平均數、經過 DADA2 質控過濾 (Filtered)、雙端拼接 (Merged) 與去除嵌合體 (Non-chimeric) 後的平均保留率 (%)。
2. 是否有 Reads 數低於 1,000 的低深度樣品或空白樣品？請列出需注意的樣品名稱。
```

### 📉 QA 2：Alpha / Beta 多樣性與 PERMANOVA (Adonis) 統計檢定解讀
```text
請讀取 results/qiime2/ 裡面的多樣性統計結果：
1. 針對不同的 SampleType（如 Human Excrement, Soil, Compost），其 Alpha 多樣性指數 (Shannon, Faith_pd) 是否有顯著差異？
2. 讀取 QIIME 2 的 Adonis (PERMANOVA) 統計檢定結果，告訴我 SampleType 對整體菌相結構說明的極限變異量 (R^2 數值) 以及 p-value 統計顯著性，並給出生物學解讀。
```

### 🦠 QA 3：物種組成分析與群落演替優勢菌群提取
```text
請讀取 results/dada2/ASV_tax.silva_138_2.tsv 與 ASV_table.tsv：
1. 整理出整體樣本中最占優勢的前 5 大菌門 (Phylum) 與前 10 大菌屬 (Genus)。
2. 比較「人體腸道 (Human Excrement)」、「土壤 (Soil Nearby Toilet)」與「堆肥過程 (Compost)」三者之間最顯著的差異特徵菌屬有哪些？
```

### 🎨 QA 4：執行 R 下游繪圖與 Markdown 綜合論文級報告撰寫
```text
請執行 03_scripts/phyloseq_analysis.R 繪製 PCoA 散佈圖與物種豐度長條圖，並綜合 MultiQC、DADA2 去噪與 QIIME 2 統計數據，為我撰寫一份完整、排版精美的 Markdown 研究總結報告，儲存至 04_viewer/report.md。
```
