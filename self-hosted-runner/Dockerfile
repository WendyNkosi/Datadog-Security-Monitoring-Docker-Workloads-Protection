FROM ubuntu:focal as base

WORKDIR /home/runner

ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NONINTERACTIVE_SEEN=true
ARG NODE_JS_VERSION=24

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        curl \
        python3 \
        python3-pip \
        python3-venv \
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
        dos2unix \
        xvfb \
    && curl -fsSL https://deb.nodesource.com/setup_${NODE_JS_VERSION}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm i --location=global npm@latest \
    && npm i --location=global corepack \
    && corepack enable \
    && apt-get autoremove -y \
    && apt-get autoclean -y \ 
    && rm -rf /var/lib/apt/lists/*

FROM base as cloud-base

ARG TERRAFORM_VERSION=1.9.8

RUN set -eux; \
    if [ "$(uname -m)" = "x86_64" ]; then \
      export CURRENT_ARCH="amd64"; \
      export AWS_CLI_ARCH="x86_64"; \
    else \
      export CURRENT_ARCH="arm64"; \
      export AWS_CLI_ARCH="aarch64"; \
    fi; \
    curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${CURRENT_ARCH}.zip -o /tmp/terraform.zip; \
    unzip /tmp/terraform.zip -d /tmp; \
    mv /tmp/terraform /usr/local/bin/; \
    rm -rf /tmp/*; \
    terraform version; \
    curl https://awscli.amazonaws.com/awscli-exe-linux-${AWS_CLI_ARCH}.zip -o awscliv2.zip; \
    unzip awscliv2.zip; \
    ./aws/install; \
    rm -rf ./aws awscliv2.zip; \
    aws --version

FROM cloud-base as runner-base
RUN npm install -g @datadog/datadog-ci

RUN terraform -install-autocomplete
ARG DOTNET_DIR=/opt/hostedtoolcache/dotnet
RUN mkdir -p ${DOTNET_DIR} && \
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --version 6.0.428 --install-dir ${DOTNET_DIR} && \
    /tmp/dotnet-install.sh --version 7.0.410 --install-dir ${DOTNET_DIR} && \
    /tmp/dotnet-install.sh --version 8.0.204 --install-dir ${DOTNET_DIR} && \
    /tmp/dotnet-install.sh --version 10.0.100 --install-dir ${DOTNET_DIR} && \
    rm /tmp/dotnet-install.sh
    
ENV DOTNET_ROOT=${DOTNET_DIR}
ENV PATH="${DOTNET_DIR}:${DOTNET_DIR}/tools:$PATH"

ENV PATH="$PATH:/home/runner/.dotnet/tools"
RUN dotnet tool update -g dd-trace
RUN dotnet tool install -g dotnet-reportgenerator-globaltool

ARG RUNNER_VERSION=2.330.0
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NONINTERACTIVE_SEEN=true
ENV GITHUB_ORG=WendyNkosi
ENV DESTINATION=runner-cache-server:/var/cache
ENV CONTAINER_NAME=gha_runner
ENV RUNNER_LABELS="linux,x64,ecs"

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
RUN chmod +x start.sh \
    && dos2unix start.sh

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
