# 🧬 16S Microbiome Amplicon Analysis (nf-core/ampliseq) - HPC & AI Automation Guide

This project provides a complete practical guide combining **AI Coding Agents** with **`nf-core/ampliseq` (16S amplicon analysis pipeline)** on the **NCHC Nano4 Slurm HPC** environment.

## 🧭 Getting Started

### Tutorial Datasets

| Dataset | Samples | FASTQ Count | Sequencing Mode | Input Path | Output Path |
| :--- | ---: | ---: | :--- | :--- | :--- |
| **Moving Pictures (Default)** | 34 | 34 | Single-end | `01_data/` | `results/` |
| **Gut-to-Soil (Tutorial 4, Optional)** | 104 | 208 | Paired-end | `examples/gut-to-soil/data/` | `results/gut-to-soil/` |

- Moving Pictures' 34 FASTQs are included in the repository; available immediately after clone.
- Gut-to-Soil FASTQs are excluded from Git; run `bash examples/gut-to-soil/download_data.sh` to download and verify fixed SHA-256 checksums.
- Tutorial 4 uses independent data, logs, work, and results paths, ensuring main Moving Pictures dataset files are preserved.

### Nano4 Prerequisites

- Ability to log in to Nano4 with sufficient quota under `/work/$USER`.
- Authorized `<PROJECT_ID>`; run account/partition preflight immediately before each submission.
- `GOV115088` is a dedicated biomedical account usable only with explicitly allowed live `ngs*` partitions; general GPU partitions require an authorized general wallet project.
- Do not commit personal project IDs to version control; specify via `sbatch --account="<PROJECT_ID>"` at submission time.
- Login nodes require Git, Bash, Python 3, and `uv`. Tutorial 4 additionally requires `curl`, `unzip`, `sha256sum`, and `gzip`.

### Recommended Learning Paths

| User Profile | Recommended Sequence |
| :--- | :--- |
| Quick Zero-Prerequisite Experience | Tutorial 0 (Standalone, No Clone, No Skill) |
| First-Time Users | Tutorial 0 → Tutorial 1 → Tutorial 2 |
| AI Agent Operator | Tutorial 0 → Tutorial 1 → Tutorial 3 |
| Advanced Paired-end Practice | Complete main tutorial then proceed to Tutorial 4 |
| Instructors / Teachers | Review `course_syllabus.md` first, then arrange Tutorials 0–4 |

---

## 📂 Directory Structure

The project adopts a clear "feature-oriented" 3-tier structure:

```text
nf-core-ampliseq/
├── 📄 README.md             # 🎓 Step-by-step tutorial guide (Traditional Chinese)
├── 📄 README_en.md          # 🎓 Step-by-step tutorial guide (English)
├── 📄 course_syllabus.md    # Course syllabus for instructors
├── 📄 nextflow.config       # Nextflow local executor & Singularity settings
├── 📂 01_data/              # Sample data (FASTQ, samplesheet, metadata)
├── 📂 02_config/            # HPC & Singularity container configurations
├── 📂 03_scripts/           # Slurm batch scripts & AI prompt templates
├── 📂 04_viewer/            # Integrated glassmorphism dashboard + analysis report
├── 📂 examples/             # Gut-to-Soil optional data & isolated scripts
└── 📂 .agents/              # Nano4 Slurm & ampliseq AI Agent skills
```

### Detailed File Descriptions:
- [01_data/](01_data/)
  - `fastq/`: 34 test sample single-end FASTQ files (`.fastq.gz`)
  - `samplesheet.template.tsv`: Portable samplesheet template
  - `samplesheet.tsv`: Generated dynamically by `prepare_samplesheet.sh` using current clone path (not tracked in Git)
  - `metadata.tsv`: Experimental grouping & metadata table (first header column must be `sampleID`)
- [02_config/](02_config/)
  - `setup_environment.sh`: HPC environment module loader & Singularity cache path settings
  - `nextflow_singularity.config`: Singularity mounting template (with `-B /tmp:/tmp` fix)
- [03_scripts/](03_scripts/)
  - `prepare_samplesheet.sh`: Generates `samplesheet.tsv` containing absolute FASTQ paths based on clone location
  - `prepare_assets.sh`: Pre-downloads Pipeline, Singularity images, and SILVA reference database on login node
  - `submit_ampliseq.slurm`: Slurm submission bash script
  - `agent_prompts_example.md`: Prompt library for AI Agent automation
  - `phyloseq_analysis.R`: R downstream analysis script (phyloseq + PCoA)
- [04_viewer/](04_viewer/)
  - `index.html`: Integrated glassmorphism dashboard to switch & view all HTML reports in one page
  - `report.md`: Demonstration analysis report (reference for instructors; generated automatically by AI for students)
- `examples/gut-to-soil/`
  - `download_data.sh`: Downloads, verifies, and prepares 104 paired-end optional dataset samples
  - `data/`: Isolated metadata, samplesheet, and FASTQ locations
  - `submit_ampliseq.slurm`: Submission script using isolated logs, work, and results directories

### Supplementary Tutorial Files

- [tutorial_0_hpc_slurm_standalone_quickstart_en.md](tutorial_0_hpc_slurm_standalone_quickstart_en.md): Standalone quickstart guide (No Git Clone, No Skill, includes universal prompts & Markdown report generation).
- [tutorial_1_hpc_slurm_ai_quickstart_en.md](tutorial_1_hpc_slurm_ai_quickstart_en.md): Nano4, wallet, partition, and first Slurm job.
- [tutorial_2_16S_manual_guide_en.md](tutorial_2_16S_manual_guide_en.md): Complete manual guide for Moving Pictures single-end dataset.
- [tutorial_3_16S_ai_prompt_guide_en.md](tutorial_3_16S_ai_prompt_guide_en.md): AI Agent prompt library and results interpretation for Moving Pictures dataset.
- [tutorial_4_gut_to_soil_optional_en.md](tutorial_4_gut_to_soil_optional_en.md): Optional Gut-to-Soil paired-end exercise with isolated data and output paths.
- [course_syllabus.md](course_syllabus.md): Instructor syllabus detailing goals, learning outcomes, and schedule.

---

## 🚀 Step-by-Step Tutorial

---

### Step 0: Clone Repository & Navigate to Workspace

> This is the **very first step** for students to ensure execution in the correct folder.
> To restart a clean practice, clone to a new directory instead of deleting existing `work/` or `results/`.

```bash
# 1. Clone this repository into your workspace
cd "/work/$USER"
git clone https://github.com/gemini960114/nf-core-ampliseq.git

# 2. Enter project directory (all subsequent commands execute here)
cd nf-core-ampliseq

# 3. Rebuild absolute FASTQ paths in samplesheet based on current clone location
bash 03_scripts/prepare_samplesheet.sh

# 4. Ensure Slurm logs directory exists
mkdir -p logs

# 5. Verify directory structure
ls -la
```

If directory already exists, create a fresh practice clone:

```bash
git clone https://github.com/gemini960114/nf-core-ampliseq.git \
  nf-core-ampliseq-practice
cd nf-core-ampliseq-practice
bash 03_scripts/prepare_samplesheet.sh
mkdir -p logs
```

---

### Step 1: Data & Metadata Preparation (`01_data/`)

1. **Verify Samplesheet Format** (`samplesheet.tsv`):
   - **Single-end** columns: `sample\tfastq_1`
2. **Verify Metadata Format** (`metadata.tsv`):
   - First header column must be `sampleID`.
   - Replace hyphens `-` with underscores `_` in column names (e.g. `body_site`).

```bash
# Verify samplesheet columns
head -3 01_data/samplesheet.tsv

# Verify metadata header
head -1 01_data/metadata.tsv
```

---

### Step 2: Prepare Pipeline, Container & Reference Assets on Login Node

> When using **AI Agent (Recommended)**, Step 2 is performed automatically by AI. First-time execution requires internet access; cached assets will be reused afterwards.

#### 2.1 Check Prerequisites & Install `uv`
`prepare_assets.sh` requires `uv` (used to pin `nf-core==4.0.3`). If `uv` is not installed on your account, run the following on the login node:
> **Note**: The official installer places `uv` under `~/.local/bin/uv` and writes PATH to `~/.bashrc`. Run `source ~/.bashrc` (or add `export PATH="$HOME/.local/bin:$PATH"`) after installation to ensure your current shell recognizes the `uv` command.

```bash
# If uv is not installed, run:
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

#### 2.2 Prepare Assets

Each user should run the preparation script on the login node. Assets are stored under the current account's own `/work/${USER}/` directories.

```bash
module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7

export NXF_SINGULARITY_CACHEDIR="/work/${USER}/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3"
bash 03_scripts/prepare_assets.sh
```

Personal assets will be cached under:

```text
/work/$USER/nf-core_download/ampliseq-2.18.0/
/work/$USER/containers/singularity_cache/ampliseq-2.18.0_nfcore-4.0.3/
/work/$USER/reference_databases/ampliseq/silva-138.2/
```

---

### Step 3: Compute Resource & Slurm Task Submission (`03_scripts/`)

#### Method A: One-Click Automation via AI Agent (Recommended)

Send the following prompt directly to the AI Agent (the Agent will check Nano4 account and partition policies before submitting ampliseq):

> **AI Prompt Example (Copy & Paste to AI)**:
> ```
> Please complete read-only preflight using nano4-slurm-operations, then use slurm-ampliseq-guide to submit the Moving Pictures 16S single-end analysis job on the ngs250g partition.
> My Slurm project account code is <PROJECT_ID>.
> Input directory is under 01_data/; get absolute project path via pwd and confirm FASTQ paths in samplesheet.tsv are valid.
> Verify nextflow.config, prepare ampliseq 2.18.0, Singularity images, and SILVA 138.2 on login node via uv, generate Slurm script, submit sbatch, and monitor progress asynchronously.
> Report MultiQC web report link and results upon completion.
> ```

#### Method B: Manual Slurm Batch Submission

Replace `<PROJECT_ID>` with your authorized Slurm project code, then execute from project root:
```bash
bash 03_scripts/prepare_samplesheet.sh
mkdir -p logs

module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7
bash 03_scripts/prepare_assets.sh

export SLURM_ACCOUNT="<PROJECT_ID>"
bash .agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh \
  --project "$SLURM_ACCOUNT" --partition "ngs250g"
sbatch --account="$SLURM_ACCOUNT" 03_scripts/submit_ampliseq.slurm
```
Check progress via `squeue -u $USER`.

---

## 📊 Output Reports & Data Visualization

Upon successful completion, the `results/` folder is generated under project root:

1. **MultiQC Comprehensive Report**: `results/multiqc/multiqc_report.html`
2. **Pipeline Overview Summary**: `results/summary_report/summary_report.html`
3. **QIIME 2 Interactive Visualizations**:
   - **Taxonomy Barplot**: `results/qiime2/barplot/index.html`
   - **Alpha Rarefaction Curves**: `results/qiime2/alpha-rarefaction/index.html`
   - **Beta Diversity PCoA 3D Emperor Plot**: `results/qiime2/diversity/beta_diversity/bray_curtis_pcoa_results-PCoA/index.html`
4. **Nextflow Execution Report**: `results/pipeline_info/execution_report_*.html`

### 🌐 Integrated Interactive Dashboard (Recommended!)

Establish SSH tunnel on your local machine:

```bash
ssh -L 8000:localhost:8000 <ACCOUNT>@<HPC_LOGIN_HOST>
```

Start Python HTTP web server in project root on HPC:

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory .
```

Open browser locally at:

```text
http://localhost:8000/04_viewer/index.html
```

---

## 🔧 Troubleshooting & FAQ

| Symptom | Cause | Solution |
| :--- | :--- | :--- |
| `sbatch: error: Invalid account` | Incorrect or unauthorized Slurm account code | Use `sbatch --account="<PROJECT_ID>" ...` to specify valid account |
| `sbatch: error: No project ID was assigned` | Account not specified or subtask re-submitting sbatch | Check `--account` & ensure `nextflow.config` sets `process { executor = 'local' }` |
| QIIME 2 error `rachis` / temp dir failure | Python 3.12 temp directory isolation issue | Ensure `singularity.runOptions = '-B /tmp:/tmp'` in config |
| Barrnap WARN: No rRNA detected | 16S V4 amplicon fragment too short (120bp) | Normal behavior; pass `--skip_barrnap` to bypass |
| Slurm Job Status `PD (Resources)` queued long | `ngs250g` node busy | Check `squeue -p ngs250g`; run preflight if switching partition |

---

## ❓ Frequently Asked Q&A Prompt Examples

### 1. Task Submission & Automation
- 🎓 **Student Prompt**:
  > "Please verify my `<PROJECT_ID>` and `ngs250g` using `nano4-slurm-operations`, then submit the 34 Moving Pictures single-end samples using `slurm-ampliseq-guide`. Validate inputs, prepare assets on login node, submit sbatch, and monitor progress asynchronously; report MultiQC link when complete."

### 8. Project Authorization & Partition Verification
- 🎓 **Student Prompt**:
  > "Which of the following Partitions can project GOV115088 use? Please help confirm, thank you!
  > `ngs8g` / `ngs16g` / `ngs32g` / `ngs62g` / `ngs125g`"
- 💡 **AI Response Summary**:
  - Run `scontrol show partition` to inspect `AllowAccounts` policies and Slurm associations.
  - **Conclusion & Compatibility Table**:
    | Partition Name | Available (GOV115088) | Allowed Project Accounts (AllowAccounts) |
    | :--- | :--- | :--- |
    | `ngs62g` | ✅ Available | `mst109178`, `gov108018`, `gov115088` |
    | `ngs8g` | ❌ Prohibited | `mst109178`, `gov108018` |
    | `ngs16g` | ❌ Prohibited | `mst109178`, `gov108018` |
    | `ngs32g` | ❌ Prohibited | `mst109178`, `gov108018` |
    | `ngs125g` | ❌ Prohibited | `mst109178`, `gov108018` |
  - Project `GOV115088` can currently use `ngs62g` among the listed partitions, but cannot use `ngs8g`, `ngs16g`, `ngs32g`, or `ngs125g`.
