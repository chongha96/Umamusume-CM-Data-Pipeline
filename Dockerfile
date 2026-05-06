FROM nvidia/cuda:13.2.1-cudnn-runtime-ubuntu22.04

#Change Torch version based on GPU supported CUDA
ARG TORCH_VERSION="cu128"

ENV DBT_PROFILES_DIR=/app/dbt_uma
ENV DEBIAN_FRONTEND=noninteractive
ENV DBT_PARTIAL_PARSE=false


# Deadsnakes required for installing Python 3.12 on Ubuntu 22.04
RUN apt-get update && apt-get install -y software-properties-common tzdata && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    curl \
    git && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    rm -rf /var/lib/apt/lists/*

# Set Python 3.12 and get-pip
RUN ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12

WORKDIR /app

#Installing larger packages separately for faster build time for future
RUN pip install --no-cache-dir torch torchvision --index-url "https://download.pytorch.org/whl/"${TORCH_VERSION}
RUN pip install dbt-bigquery google-cloud-bigquery

COPY pyproject.toml .
RUN pip install --no-cache-dir .

COPY . .

CMD ["sh", "-c", "python main.py && cd dbt_uma && dbt clean && dbt deps && dbt run --no-partial-parse"]

