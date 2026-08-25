# 📂 03_scripts Slurm 作業腳本與 AI 提示詞資料夾

本資料夾包含發送至 Slurm 集群 (`ngs62g` 分割區) 的提交腳本與 AI Agent 自然語言提示詞範例。

---

## 📁 內容清單

1. **`prepare_assets.sh`**：使用固定的 nf-core/tools 4.0.3，在登入節點預先下載 ampliseq 2.18.0、Singularity images 與 SILVA 138.2；版本化快取會透過符號連結重用既有映像，避免重複下載。
2. **`submit_ampliseq.slurm`**：Slurm sbatch 批次作業腳本（分配 32 CPUs / 250G RAM）。
3. **`prepare_samplesheet.sh`**：依目前 clone 位置產生包含 FASTQ 絕對路徑的 `samplesheet.tsv`。
4. **`agent_prompts_example.md`**：給 AI Agent 下達自動化派送與背景監控指令的 Prompt 範本庫。
5. **`phyloseq_analysis.R`**：R 下游分析範例腳本，使用 phyloseq 套件以 `results/dada2/ASV_table.tsv` 與 `ASV_tax.silva_138_2.tsv` 繪製物種豐度長條圖與 PCoA。

提交時必須使用自己的 Slurm 計畫代碼：

```bash
mkdir -p logs
bash 03_scripts/prepare_assets.sh
sbatch --account="<PROJECT_ID>" 03_scripts/submit_ampliseq.slurm
```
