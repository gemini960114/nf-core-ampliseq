# 📂 04_viewer — 成果報告整合型儀表板

本資料夾包含分析完成後，用來瀏覽所有 HTML 報告的整合型 Web 儀表板。

---

## 📁 內容清單

1. **`index.html`**：整合型玻璃擬態儀表板，嵌入所有 nf-core/ampliseq 分析報告（MultiQC、Pipeline 摘要、QIIME 2 物種長條圖、Alpha 稀疏曲線、3D Beta PCoA）。
2. **`report.md`**：AI 自動生成的分析結果摘要報告（學生跑完分析後由 AI 產生，此為示範參考版本）。

---

## 🚀 啟動方式

先在自己的電腦建立 SSH tunnel：

```bash
ssh -L 8000:localhost:8000 <ACCOUNT>@<HPC_LOGIN_HOST>
```

接著在這個 SSH 連線中的專案根目錄執行：

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory .
```

最後在自己電腦的瀏覽器造訪：

- **整合型儀表板**：`http://localhost:8000/04_viewer/index.html`

> **注意**：`index.html` 中的 iframe 連結指向 `results/` 子目錄，需要在分析完成並產生 `results/` 後才能正確顯示內容。
