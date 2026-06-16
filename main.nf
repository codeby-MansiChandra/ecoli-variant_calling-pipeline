#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.reads  = "data/reads/*_{1,2}.fastq.gz"
params.genome = "data/genome/ecoli_ref.fna"
params.outdir = "results"

process FASTQC {
    tag "$sample_id"
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "*_fastqc.{html,zip}"

    script:
    """
    fastqc ${reads[0]} ${reads[1]}
    """
}

process TRIM {
    tag "$sample_id"
    publishDir "${params.outdir}/trimmed", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}_1_trimmed.fastq.gz"), path("${sample_id}_2_trimmed.fastq.gz")

    script:
    """
    trimmomatic PE -phred33 \
        ${reads[0]} ${reads[1]} \
        ${sample_id}_1_trimmed.fastq.gz ${sample_id}_1_unpaired.fastq.gz \
        ${sample_id}_2_trimmed.fastq.gz ${sample_id}_2_unpaired.fastq.gz \
        TRAILING:20 MINLEN:25
    rm -f *_unpaired.fastq.gz
    """
}

process BWA_INDEX {
    tag "$genome"

    input:
    path genome

    output:
    tuple path(genome), path("${genome}.*")

    script:
    """
    bwa index ${genome}
    """
}

process BWA_ALIGN {
    tag "$sample_id"
    publishDir "${params.outdir}/aligned", mode: 'copy'

    input:
    tuple path(genome), path(index)
    tuple val(sample_id), path(read1), path(read2)

    output:
    tuple val(sample_id), path("${sample_id}.aligned.sorted.bam"), path("${sample_id}.aligned.sorted.bam.bai")

    script:
    """
    bwa mem ${genome} ${read1} ${read2} > ${sample_id}.sam
    samtools view -S -b ${sample_id}.sam > ${sample_id}.bam
    samtools sort -m 500M ${sample_id}.bam -o ${sample_id}.aligned.sorted.bam
    samtools index ${sample_id}.aligned.sorted.bam
    rm ${sample_id}.sam ${sample_id}.bam
    """
}

process VARIANT_CALL {
    tag "$sample_id"
    publishDir "${params.outdir}/variants", mode: 'copy'

    input:
    tuple path(genome), path(index)
    tuple val(sample_id), path(bam), path(bai)

    output:
    tuple val(sample_id), path("${sample_id}_variants.vcf")

    script:
    """
    bcftools mpileup -O b -o ${sample_id}_raw.bcf -f ${genome} ${bam}
    bcftools call --ploidy 1 -m -v -o ${sample_id}_variants.vcf ${sample_id}_raw.bcf
    rm ${sample_id}_raw.bcf
    """
}

process FILTER_VARIANTS {
    tag "$sample_id"
    publishDir "${params.outdir}/variants", mode: 'copy'

    input:
    tuple val(sample_id), path(vcf)

    output:
    tuple val(sample_id), path("${sample_id}_filtered.vcf")

    script:
    """
    bcftools filter -s LowQual -e 'QUAL<20 || DP<10' ${vcf} > ${sample_id}_filtered.vcf
    """
}

workflow {
    reads_ch  = Channel.fromFilePairs(params.reads, checkIfExists: true).map { id, reads -> tuple(id, reads[0], reads[1]) }
    genome_ch = Channel.fromPath(params.genome, checkIfExists: true)

    fastqc_input = Channel.fromFilePairs(params.reads, checkIfExists: true)
    FASTQC(fastqc_input)

    trimmed_ch = TRIM(fastqc_input)
    index_ch   = BWA_INDEX(genome_ch)

    aligned_ch = BWA_ALIGN(index_ch, trimmed_ch)
    variants_ch = VARIANT_CALL(index_ch, aligned_ch)
    FILTER_VARIANTS(variants_ch)
}
