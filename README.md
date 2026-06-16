# E. coli Variant Calling Pipeline (Nextflow)

A reproducible, paired-end variant calling pipeline for whole genome sequencing data, built with Nextflow and designed to run locally, in Docker, or on AWS Batch.

## Overview

This pipeline takes raw paired-end FASTQ files and produces a filtered list of genetic variants (SNPs and indels) against a reference genome. It automates quality control, trimming, alignment, variant calling, and filtering into a single command.

## Pipeline Steps

1. FastQC quality control on raw reads
2. Trimmomatic adapter and quality trimming (paired-end)
3. BWA-MEM alignment to reference genome
4. SAMtools sorting and indexing
5. bcftools variant calling
6. bcftools variant filtering (QUAL and depth thresholds)

## Tools

| Tool | Purpose |
|------|---------|
| FastQC | Read quality control |
| Trimmomatic | Adapter and quality trimming |
| BWA | Genome alignment |
| SAMtools | BAM processing |
| bcftools | Variant calling and filtering |
| Nextflow | Workflow orchestration |

## Dataset

- Sample: SRR2584863 (E. coli K-12 REL7179B)
- Type: Paired-end Illumina, 150bp
- Source: NCBI SRA / ENA
- Reference: E. coli K-12 MG1655 (GCF_000005845.2)

## Results

- 34,379 total variants called
- 33,677 high-confidence variants after filtering
- 702 variants flagged as low quality (QUAL<20 or DP<10)

## Project Structure

