# Gut-to-Soil Tutorial 4 data

此目錄只供選修 Tutorial 4 使用，不會覆寫根目錄的 Moving Pictures
`01_data/`。

- `metadata.tsv`：已標準化的參考 metadata。
- `samplesheet.template.tsv`：104 組 paired-end 樣本的可攜式範本。
- `samplesheet.tsv`：下載後依 clone 路徑產生，不納入 Git。
- `fastq/`：執行 `../download_data.sh` 後取得 208 個 FASTQ，不納入 Git。

從 repository 根目錄執行：

```bash
bash examples/gut-to-soil/download_data.sh
```
