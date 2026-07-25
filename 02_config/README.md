# 📂 02_config HPC 與 Singularity 容器配置資料夾

本資料夾包含在國網中心 (NCHC) HPC 超級電腦上執行 Nextflow 與 Singularity 容器所需的環境說明與配置樣板。

---

## 📁 內容清單

1. **`setup_environment.sh`**：載入 Nextflow/Singularity 模組與設定目前使用者個人 Singularity cache 的 shell 腳本。
2. **`nextflow_singularity.config`**：額外的 Singularity profile 設定；專案根目錄的 `nextflow.config` 則固定使用本機 executor 並設定 `/tmp` 掛載。
