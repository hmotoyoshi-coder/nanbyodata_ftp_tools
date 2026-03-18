FROM debian:bookworm-slim

ARG UID
ARG GID
ARG REMOTE_USER_GROUP
ARG REMOTE_USER


RUN groupadd -g ${GID} ${REMOTE_USER_GROUP} && \
    useradd -m -u ${UID} -g ${GID} ${REMOTE_USER}

RUN mkdir -p /work && chown ${UID}:${GID} /work

WORKDIR /work

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    bash \
    openssh-client \
    sshpass

RUN curl -L https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-linux-amd64.zip -o duckdb.zip \
    && unzip duckdb.zip -d /usr/local/bin \
    && rm duckdb.zip

USER ${UID}:${GID}

ENTRYPOINT [ "/bin/bash" ]