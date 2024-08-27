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
        wget gpg ca-certificates \
    # Ansible
    && wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu jammy main" | tee /etc/apt/sources.list.d/ansible.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ansible \
        ansible-lint \
        python3-argcomplete \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN adduser -u $USER_UID --disabled-password --gecos "" $USERNAME  \
    && chown -R $USERNAME /app \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && echo "[[ -f ~/.prompt_git ]] && source ~/.prompt_git" >> /home/$USERNAME/.bashrc

USER appuser

COPY .prompt_git /home/$USERNAME

RUN activate-global-python-argcomplete --user

CMD ["sleep", "infinity"]