FROM mambaorg/micromamba:1.5.8

ARG MAMBA_USER=mambauser

# Copy environment definition and build conda environment
COPY --chown=${MAMBA_USER}:${MAMBA_USER} environment.yml /tmp/environment.yml
RUN micromamba create --yes --name exome --file /tmp/environment.yml \
    && micromamba clean --all --yes

# Set PATH to environment binaries
ENV PATH=/opt/conda/envs/exome/bin:$PATH
WORKDIR /opt/exome

# Copy pipeline orchestrator, modules, and default container configuration
COPY --chown=${MAMBA_USER}:${MAMBA_USER} run_exome.sh ./
COPY --chown=${MAMBA_USER}:${MAMBA_USER} modules/ ./modules/
COPY --chown=${MAMBA_USER}:${MAMBA_USER} exome.config.example ./exome.config

# Set execution permissions
RUN chmod +x run_exome.sh modules/*.sh

# Container entrypoint
ENTRYPOINT ["/opt/exome/run_exome.sh"]
