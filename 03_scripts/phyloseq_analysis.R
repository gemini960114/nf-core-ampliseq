# ==============================================================================
# 16S Amplicon Microbiome Downstream Analysis in R (phyloseq)
# ==============================================================================

suppressPackageStartupMessages({
  library(phyloseq)
  library(ggplot2)
})

otu_path <- "results/dada2/ASV_table.tsv"
tax_path <- "results/dada2/ASV_tax.silva_138_2.tsv"
metadata_path <- "01_data/metadata.tsv"
group_column <- "body_site"

required_files <- c(otu_path, tax_path, metadata_path)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop("找不到必要輸入檔：", paste(missing_files, collapse = ", "))
}

# QIIME 2 的 #q2:types 行以 comment.char="#" 略過；quote="" 避免註記欄中的
# 不成對引號破壞 TSV 欄位解析。
otu_mat <- read.table(
  otu_path,
  header = TRUE,
  row.names = 1,
  sep = "\t",
  check.names = FALSE,
  quote = "",
  comment.char = ""
)
tax_mat <- read.table(
  tax_path,
  header = TRUE,
  row.names = 1,
  sep = "\t",
  check.names = FALSE,
  quote = "",
  comment.char = ""
)
meta_df <- read.table(
  metadata_path,
  header = TRUE,
  row.names = 1,
  sep = "\t",
  check.names = FALSE,
  quote = "",
  comment.char = "#"
)

if (!group_column %in% colnames(meta_df)) {
  stop("metadata 缺少分組欄位：", group_column)
}

shared_taxa <- intersect(rownames(otu_mat), rownames(tax_mat))
shared_samples <- intersect(colnames(otu_mat), rownames(meta_df))
if (length(shared_taxa) == 0) {
  stop("ASV count table 與 taxonomy table 沒有共同 ASV ID")
}
if (length(shared_samples) < 2) {
  stop("ASV count table 與 metadata 的共同樣本少於 2 個")
}

otu_mat <- otu_mat[shared_taxa, shared_samples, drop = FALSE]
tax_mat <- tax_mat[shared_taxa, , drop = FALSE]
meta_df <- meta_df[shared_samples, , drop = FALSE]
meta_df[[group_column]] <- factor(meta_df[[group_column]])

ps <- phyloseq(
  otu_table(as.matrix(otu_mat), taxa_are_rows = TRUE),
  tax_table(as.matrix(tax_mat)),
  sample_data(meta_df)
)
ps <- prune_samples(sample_sums(ps) > 0, ps)
if (nsamples(ps) < 2) {
  stop("移除零 reads 樣本後少於 2 個樣本，無法進行 PCoA")
}

# Phylum level 相對豐度長條圖。
ps_phylum <- tax_glom(ps, taxrank = "Phylum", NArm = FALSE)
ps_phylum <- transform_sample_counts(
  ps_phylum,
  function(counts) counts / sum(counts)
)
p_bar <- plot_bar(ps_phylum, x = group_column, fill = "Phylum") +
  facet_wrap(stats::as.formula(paste("~", group_column)), scales = "free_x") +
  theme_minimal() +
  labs(
    title = "Phylum Relative Abundance by Body Site",
    x = "Body Site",
    y = "Relative abundance"
  )

# Bray-Curtis PCoA。
ps_ord <- ordinate(ps, method = "PCoA", distance = "bray")
p_pcoa <- plot_ordination(ps, ps_ord, color = group_column) +
  geom_point(size = 3) +
  theme_bw() +
  labs(title = "PCoA Ordination (Bray-Curtis)", color = "Body Site")

dir.create("results", showWarnings = FALSE, recursive = TRUE)
ggsave("results/phyloseq_phylum_bar.png", p_bar, width = 10, height = 6)
ggsave("results/phyloseq_pcoa_bray.png", p_pcoa, width = 8, height = 6)
cat(
  sprintf(
    "Phyloseq 下游分析完成：%d 個樣本、%d 個 ASVs。\n",
    nsamples(ps),
    ntaxa(ps)
  )
)
