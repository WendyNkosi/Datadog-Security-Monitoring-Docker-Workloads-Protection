FROM ubuntu:22.04 as base
# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /home/runner

# Install comprehensive dependencies
RUN apt update -y \
    && apt install -y --no-install-recommends\
        curl \
        jq \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        apt-utils \
        apt-transport-https \
        build-essential \
        python3 \
        python3-pip \
        postgresql-client \
        git \
        ssh \
        zip \
        unzip \ 
        wget \
        file \
        libicu-dev \
        rsync \
        libgtk2.0-0 \
        libgtk-3-0 \
        libgbm-dev \
        libnotify-dev \
        libgconf-2-4 \
        libnss3 \
        libxss1 \
        libasound2 \
        libxtst6 \
        xauth \
        xvfb \
    && apt-get autoremove -y \
    && apt-get autoclean -y \ 
    && rm -rf /var/lib/apt/lists/*


FROM base as arch-base

ARG VAULT_VERSION=1.8.5

RUN if [ "$(uname -m)" = "x86_64" ]; then \
      export CURRENT_ARCH="amd64" \
      && export AWS_CLI_ARCH="x86_64"; \
    else \
      export CURRENT_ARCH="arm64" \
      && export AWS_CLI_ARCH="aarch64"; \
    fi \
    && curl -o vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${CURRENT_ARCH}.zip \
    && unzip vault.zip \
    && mv vault /usr/local/bin \
    && rm vault.zip \
    && curl https://awscli.amazonaws.com/awscli-exe-linux-${AWS_CLI_ARCH}.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf ./aws awscliv2.zip \
    && aws --version

FROM arch-base as runner-base
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get update -y \
    && apt-get install --no-install-recommends -y sudo \
    && if [ "$(uname -m)" = "x86_64" ]; then \
        curl -o actions-runner.tar.gz -sL https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz; \
    else \
        export CURRENT_ARCH="arm64" \
        && curl -o actions-runner.tar.gz -sL https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${CURRENT_ARCH}-${RUNNER_VERSION}.tar.gz; \
    fi \
    && useradd -m -d /home/runner -b /home/runner -U runner \
    && echo "runner ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers \
    && mkdir -p /opt/hostedtoolcache \
    && chown runner:runner /opt/hostedtoolcache \
    && chmod g+rwx /opt/hostedtoolcache \
    && tar xzf ./actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && cat ./bin/installdependencies.sh \
    && ./bin/installdependencies.sh \
    && rm -rf /var/lib/apt/lists/*
    
COPY start.sh .

USER runner

VOLUME ["/opt/hostedtoolcache"]

ENTRYPOINT ["/home/runner/start.sh"]

FROM runner-base as docker-runner-base

USER root
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

USER runner
