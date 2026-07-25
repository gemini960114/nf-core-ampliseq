# ==============================================================================
# 16S Amplicon Microbiome Downstream Analysis in R (phyloseq)
# ==============================================================================
# 本腳本示範如何載入 nf-core/ampliseq 產出的 DADA2 特徵表與物種分類表進行下游分析

library(phyloseq)
library(ggplot2)

# 1. 讀取 DADA2 ASV 數量表與物種註釋表
otu_mat <- read.table("results/dada2/ASV_table.tsv", header = TRUE, row.names = 1, sep = "\t", check.names = FALSE)
tax_mat <- read.table("results/dada2/ASV_tax.silva_138_2.tsv", header = TRUE, row.names = 1, sep = "\t", fill = TRUE)
meta_df <- read.table("01_data/metadata.tsv", header = TRUE, row.names = 1, sep = "\t")

# 2. 建立 Phyloseq 物件
OTU <- otu_table(as.matrix(otu_mat), taxa_are_rows = TRUE)
TAX <- tax_table(as.matrix(tax_mat))
META <- sample_data(meta_df)

ps <- phyloseq(OTU, TAX, META)

# 3. 繪製物種豐度長條圖 (Phylum Level)
p_bar <- plot_bar(ps, fill = "Phylum") + 
  facet_wrap(~body_site, scales = "free_x") +
  theme_minimal() +
  labs(title = "Microbiome Phylum Abundance across Body Sites")

# 4. 繪製 PCoA (Bray-Curtis Distance)
ps_ord <- ordinate(ps, method = "PCoA", distance = "bray")
p_pcoa <- plot_ordination(ps, ps_ord, color = "body_site") +
  geom_point(size = 3) +
  theme_bw() +
  labs(title = "PCoA Ordination (Bray-Curtis)")

print(p_bar)
print(p_pcoa)

# 5. 儲存繪圖結果
dir.create("results", showWarnings = FALSE)
ggsave("results/phyloseq_phylum_bar.png", p_bar, width = 10, height = 6)
ggsave("results/phyloseq_pcoa_bray.png", p_pcoa, width = 8, height = 6)
cat("Phyloseq 下游分析完成！圖表已儲存至 results/ 檔案夾。\n")
