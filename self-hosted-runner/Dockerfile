FROM ubuntu:latest
# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive
# Install comprehensive dependencies
RUN apt-get update && apt-get install -y \\
    curl wget git jq build-essential \\
    libssl-dev libffi-dev python3 python3-pip \\
    nodejs npm docker.io unzip tar gzip \\
    ca-certificates gnupg sudo openssl \\
    postgresql-client && rm -rf /var/lib/apt/lists/*
# Install AWS CLI v2
RUN wget -O "awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \\
    && unzip awscliv2.zip && ./aws/install \\
    && rm -rf awscliv2.zip aws
# Create runner user with Docker access
RUN useradd -m -s /bin/bash runner && \\
    usermod -aG docker runner && \\
    echo 'runner ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
# Download GitHub Actions runner (multi-architecture support)
ARG RUNNER_VERSION=2.330.0
RUN ARCH=$(uname -m) && \\
    if [ "$ARCH" = "aarch64" ]; then RUNNER_ARCH="arm64"; \\
    else RUNNER_ARCH="x64"; fi && \\
    wget -O actions-runner.tar.gz \\
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \\
    && tar xzf actions-runner.tar.gz && rm actions-runner.tar.gz
COPY multi-runner.sh /home/runner/multi-runner.sh

RUN chmod +x /home/runner/multi-runner.sh
ENTRYPOINT ["/home/runner/multi-runner.sh"]
