# Use a stable base image (Debian-based Miniconda)
FROM continuumio/miniconda3

# Set working directory
WORKDIR /env

# Copy Conda environment file to the container
COPY basic_report.yaml /env/basic_report.yaml

# Install Bash and basic utilities (ensure shell execution works)
RUN apt-get update && apt-get install -y bash coreutils

# Create and activate the Conda environment
RUN conda env create -f /env/basic_report.yaml

# Activate the environment by default
RUN echo "conda activate basic_report" >> ~/.bashrc
ENV PATH /opt/conda/envs/basic_report/bin:$PATH