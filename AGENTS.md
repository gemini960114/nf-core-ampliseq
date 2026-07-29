# Project execution rules

- Before any Nano4 Slurm project selection, partition choice, submission,
  monitoring, diagnosis, or cancellation, use
  `.agents/skills/nano4-slurm-operations/SKILL.md`.
- For nf-core/ampliseq work, also use
  `.agents/skills/slurm-ampliseq-guide/SKILL.md`.
- Run the Nano4 read-only preflight before submission. Resolve wallet validity,
  Slurm association, and the exact partition's Allow/DenyAccounts.
- Treat `MST109178` as a dedicated biomedical account. Use it only with a live
  `ngs*` partition that explicitly allows it. Never use it on standard GPU
  partitions.
- Use an active general wallet project for standard GPU partitions and verify the
  exact account/partition policy. Never choose which project budget to charge
  without user authorization.
- Never commit a personal project ID in `#SBATCH --account`; pass it with
  `sbatch --account="<PROJECT_ID>"`.
- Keep `logs/.gitkeep` tracked and ensure `logs/` exists before `sbatch`.
- Prepare pipeline, container, and reference assets on the login node. Do not
  download them from a compute job.
- Keep nf-core/ampliseq tasks inside the allocated node with the repository's
  local executor and Singularity configuration.
- Validate metadata, samplesheet paths, shell syntax, and required assets before
  submission.
- Use non-polling monitoring. Treat `scancel`, result deletion, and work-directory
  deletion as destructive or state-changing actions requiring exact targets and
  appropriate authorization.
