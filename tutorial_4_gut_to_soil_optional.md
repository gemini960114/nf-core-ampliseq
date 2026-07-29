# Tutorial 4（選修）：Gut-to-Soil 雙端資料

本章是進階資料替換練習，不是 repository 的預設範例。主教學固定使用
34 個 Moving Pictures 單端樣本；為避免覆寫主範例，請在另一個 clone
執行本章。

## 1. 建立獨立 clone

```bash
cd "/work/$USER"
git clone https://github.com/gemini960114/nf-core-ampliseq.git \
  nf-core-ampliseq-gut-to-soil
cd nf-core-ampliseq-gut-to-soil
```

不要在 Moving Pictures 上課用的 clone 執行後續指令。

## 2. 下載並解開資料

```bash
wget -O 01_data/metadata.raw.tsv \
  https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/sample-metadata.tsv
wget -O /tmp/gut-to-soil-demux.qza \
  https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/demux.qza

test "$(basename "$PWD")" = "nf-core-ampliseq-gut-to-soil" || {
  echo "錯誤：Tutorial 4 必須在獨立 clone 執行" >&2
  exit 1
}
rm -f 01_data/fastq/*.fastq.gz
unzip -j /tmp/gut-to-soil-demux.qza '*/data/*.fastq.gz' -d 01_data/fastq/
rm -f /tmp/gut-to-soil-demux.qza
```

## 3. 建立 paired-end 輸入

```bash
python3 examples/gut-to-soil/prepare_gut_to_soil.py
python3 examples/gut-to-soil/clean_metadata.py
bash 03_scripts/prepare_samplesheet.sh
```

驗證預期結果：

```bash
test "$(find 01_data/fastq -maxdepth 1 -name '*.fastq.gz' | wc -l)" -eq 208
test "$(awk 'END {print NR-1}' 01_data/samplesheet.tsv)" -eq 104
head -1 01_data/samplesheet.tsv
```

samplesheet 應包含 `sample`、`fastq_1`、`fastq_2` 三欄。

## 4. 準備資產、preflight 與提交

將 `<PROJECT_ID>` 換成你被授權使用的計畫。`MST109178` 只能由具有該
生醫計畫權限的人員搭配允許它的 `ngs*` partition 使用。

```bash
bash 03_scripts/prepare_assets.sh
mkdir -p logs

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

## 5. 回復主教材

Tutorial 4 的 clone 可以獨立保留或刪除；不要將它的 `01_data/`、
`results/`、`work/` 或 samplesheet 複製回 Moving Pictures 主 clone。
