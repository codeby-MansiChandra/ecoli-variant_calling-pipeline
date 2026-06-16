FROM continuumio/miniconda3:latest

LABEL maintainer="Mansi Chandra <mansibioinfo.30112001@gmail.com>"
LABEL description="E. coli variant calling pipeline - FastQC, Trimmomatic, BWA, SAMtools, bcftools"

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda config --set channel_priority strict

RUN conda install -y -n base mamba && \
    mamba install -y \
    fastqc \
    trimmomatic \
    bwa \
    samtools \
    bcftools \
    && conda clean -afy

WORKDIR /data

CMD ["/bin/bash"]
