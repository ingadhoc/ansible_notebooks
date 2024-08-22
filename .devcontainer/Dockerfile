FROM debian:bookworm-slim

ARG USERNAME=appuser
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL="C.UTF-8"
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # Basic
        git \
        sudo \
        bash-completion \
        ssh-client \
        nano \
        gnupg2 \
        # 
        # apt-utils \
        # software-properties-common \
        # build-essential \
        # jq \
        # git \
        # python3 \
        # python3-dev \
        # python3-pip && \
        ansible-lint \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN adduser -u $USER_UID --disabled-password --gecos "" $USERNAME  \
    && chown -R $USERNAME /app \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER appuser

CMD ["sleep", "infinity"]