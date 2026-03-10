FROM debian:bookworm-slim

WORKDIR work

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    bash \
    openssh-client

RUN curl -L https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-linux-amd64.zip -o duckdb.zip \
    && unzip duckdb.zip -d /usr/local/bin \
    && rm duckdb.zip

ENTRYPOINT [ "/bin/bash" ]