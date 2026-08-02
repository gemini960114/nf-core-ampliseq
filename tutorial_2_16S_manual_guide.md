# 16S 擴增子分析：Moving Pictures 手動操作指南

本教學使用 repository 內建的 34 個 Moving Pictures 單端 FASTQ，於
Nano4 以 nf-core/ampliseq 2.18.0、Nextflow 與 Singularity 執行。

## 1. Clone 與輸入驗證

```bash
cd "/work/$USER"
git clone https://github.com/gemini960114/nf-core-ampliseq.git
cd nf-core-ampliseq

find 01_data/fastq -maxdepth 1 -name '*.fastq.gz' | wc -l
bash 03_scripts/prepare_samplesheet.sh
head -3 01_data/samplesheet.tsv
head -1 01_data/metadata.tsv
```

預期 FASTQ 數量為 34；samplesheet 欄位為 `sample`、`fastq_1`，metadata
第一欄為 `sampleID`，且包含 `body_site`。

## 2. 在登入節點準備資產

### 2.1 環境與 `uv` 安裝檢查
`prepare_assets.sh` 需使用 `uv` 工具（用於固定 `nf-core==4.0.3` 工具版本）。若你的系統尚未安裝 `uv`，請在登入節點執行以下指令安裝：
> **說明**：安裝腳本預設會將 `uv` 放置於家目錄 `~/.local/bin/uv` 並寫入 `~/.bashrc`。請在安裝後執行 `source ~/.bashrc`（或加入 `export PATH="$HOME/.local/bin:$PATH"`）以確保當前 Shell 能直接識別 `uv` 指令。

```bash
# 若尚未安裝 uv，請執行：
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

### 2.2 準備資產

每位使用者都應在登入節點執行準備腳本；資產會存入目前帳號自己的 `/work/${USER}/` 目錄。

```bash
module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7

export NXF_SINGULARITY_CACHEDIR="/work/${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3"
bash 03_scripts/prepare_assets.sh
```

`prepare_assets.sh` 會預先準備或驗證 ampliseq 2.18.0、Singularity images 與 SILVA 138.2。不要在計算節點下載這些資產。

## 3. 驗證設定與 Slurm 權限

將 `<PROJECT_ID>` 替換成你被授權使用的計畫代碼。`GOV115088` 僅供具有
該生醫計畫權限的人員搭配允許它的 `ngs*` partition 使用。

```bash
bash -n 03_scripts/submit_ampliseq.slurm

bash .agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh \
  --project "<PROJECT_ID>" \
  --partition "ngs250g"
```

只有 preflight 完全通過才繼續提交。提交腳本的 Moving Pictures 參數為：

- `--single_end`
- `--trunclenf 120`
- `--metadata_category_barplot "body_site"`
- `--qiime_adonis_formula "body_site"`

## 4. 提交與查看狀態

```bash
mkdir -p logs
sbatch --account="<PROJECT_ID>" 03_scripts/submit_ampliseq.slurm
squeue -u "$USER"
```

取得 Job ID 後，可用以下指令查看一次狀態；不要建立無限輪詢迴圈：

```bash
sacct -j "<JOB_ID>" --format=JobID,State,ExitCode,Elapsed
```

## 5. 結果

成功後主要輸出包括：

- `results/multiqc/multiqc_report.html`
- `results/dada2/ASV_table.tsv`
- `results/dada2/ASV_tax.silva_138_2.tsv`
- `results/qiime2/`

如需瀏覽整合頁面，在登入節點從專案根目錄啟動：

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory .
```

再透過 SSH port forwarding 開啟
`http://localhost:8000/04_viewer/index.html`。
