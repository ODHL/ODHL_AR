# Use the official Miniconda image
FROM continuumio/miniconda3

# Set working directory
WORKDIR /env

# Copy Conda environment file
COPY basic_report.yaml /env/environment.yml

# Install the Conda environment
RUN conda env create -f /env/environment.yml

# Activate the environment by default
RUN echo "conda activate my_environment" >> ~/.bashrc
ENV PATH /opt/conda/envs/my_environment/bin:$PATH

# Set entrypoint
ENTRYPOINT ["/bin/bash"]

