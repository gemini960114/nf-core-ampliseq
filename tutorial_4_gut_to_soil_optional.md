# Tutorial 4（選修）：Gut-to-Soil 雙端資料

本章是進階資料集練習，不是 repository 的預設範例。主教學固定使用
根目錄 `01_data/` 的 34 個 Moving Pictures 單端樣本；Gut-to-Soil 的
資料、logs、work 與 results 全部使用隔離路徑，不會覆寫主範例。

## 1. Clone repository

```bash
cd "/work/$USER"
git clone https://github.com/gemini960114/nf-core-ampliseq.git
cd nf-core-ampliseq
```

## 2. 下載並準備資料

在 Nano4 登入節點執行；不要從 Slurm 計算工作下載資料。需要 `curl`、
`unzip`、`sha256sum`、`gzip` 與 Python 3。

```bash
bash examples/gut-to-soil/download_data.sh
```

下載腳本會驗證兩個來源檔的 SHA-256、確認 208 個 FASTQ、檢查 gzip，
再產生 normalized metadata 與絕對路徑 samplesheet。

驗證預期結果：

```bash
data_dir="examples/gut-to-soil/data"
test "$(find "$data_dir/fastq" -maxdepth 1 -name '*.fastq.gz' | wc -l)" -eq 208
test "$(awk 'END {print NR-1}' "$data_dir/samplesheet.tsv")" -eq 104
head -1 "$data_dir/samplesheet.tsv"
```

samplesheet 應包含 `sample`、`fastq_1`、`fastq_2` 三欄。

## 3. 準備資產、preflight 與提交

將 `<PROJECT_ID>` 換成你被授權使用的計畫。`GOV115088` 只能由具有該
生醫計畫權限的人員搭配允許它的 `ngs*` partition 使用。

```bash
bash 03_scripts/prepare_assets.sh
mkdir -p logs/gut-to-soil

bash .agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh \
  --project "<PROJECT_ID>" \
  --partition "ngs250g"

sbatch --account="<PROJECT_ID>" \
  examples/gut-to-soil/submit_ampliseq.slurm
```

選修提交腳本使用 paired-end 參數：

- `--trunclenf 250 --trunclenr 250`
- `--ignore_empty_input_files`
- `--metadata_category_barplot "SampleType"`
- `--qiime_adonis_formula "SampleType"`

提交後回報 Job ID，以 `squeue`／`sacct` 查看狀態，不使用無限輪詢。

## 4. 輸出位置

- 輸入：`examples/gut-to-soil/data/`
- Logs：`logs/gut-to-soil/`
- Nextflow work：`work/gut-to-soil/`
- Results：`results/gut-to-soil/`

根目錄的 `01_data/`、Moving Pictures samplesheet 與預設 results 不會被
Tutorial 4 修改。
