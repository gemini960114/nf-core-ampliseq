# Tutorial 4 (Optional): Gut-to-Soil Paired-End Dataset

This chapter is an advanced optional dataset exercise and is not the repository's default tutorial. The main guide consistently uses the 34 Moving Pictures single-end samples in root `01_data/`; Gut-to-Soil uses completely isolated paths for data, logs, work, and results, preserving the main tutorial outputs.

## 1. Clone Repository

```bash
cd "/work/$USER"
git clone https://github.com/gemini960114/nf-core-ampliseq.git
cd nf-core-ampliseq
```

## 2. Download & Prepare Data

Execute on Nano4 login node; do not download data inside compute jobs. Requires `curl`, `unzip`, `sha256sum`, `gzip`, and Python 3.

```bash
bash examples/gut-to-soil/download_data.sh
```

The download script verifies fixed SHA-256 hashes for both source files, confirms 208 FASTQs, checks gzip integrity, and generates normalized metadata and an absolute-path samplesheet.

Verify expected outputs:

```bash
data_dir="examples/gut-to-soil/data"
test "$(find "$data_dir/fastq" -maxdepth 1 -name '*.fastq.gz' | wc -l)" -eq 208
test "$(awk 'END {print NR-1}' "$data_dir/samplesheet.tsv")" -eq 104
head -1 "$data_dir/samplesheet.tsv"
```

The samplesheet should contain three columns: `sample`, `fastq_1`, `fastq_2`.

## 3. Prepare Assets, Preflight & Submit

Replace `<PROJECT_ID>` with your authorized project account code. `GOV115088` is restricted to authorized biomedical allocation users using allowed `ngs*` partitions.

```bash
bash 03_scripts/prepare_assets.sh
mkdir -p logs/gut-to-soil

bash .agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh \
  --project "<PROJECT_ID>" \
  --partition "ngs250g"

sbatch --account="<PROJECT_ID>" \
  examples/gut-to-soil/submit_ampliseq.slurm
```

The optional submission script uses paired-end parameters:

- `--trunclenf 250 --trunclenr 250`
- `--ignore_empty_input_files`
- `--metadata_category_barplot "SampleType"`
- `--qiime_adonis_formula "SampleType"`

Report Job ID after submission, checking status via `squeue` / `sacct` without continuous polling loops.

## 4. Output Locations

- Input: `examples/gut-to-soil/data/`
- Logs: `logs/gut-to-soil/`
- Nextflow work: `work/gut-to-soil/`
- Results: `results/gut-to-soil/`

Root `01_data/`, Moving Pictures samplesheet, and default results directory remain untouched by Tutorial 4.
