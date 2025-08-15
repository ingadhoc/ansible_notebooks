# Usamos la base oficial de Debian Bookworm
FROM debian:bookworm-slim

ARG USERNAME=appuser
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV DEBIAN_FRONTEND=noninteractive

# 1. Como ROOT, instalamos las dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    git sudo ssh-client python3-venv python3-pip gnupg locales \
    && rm -rf /var/lib/apt/lists/*

# 2. Configuramos el idioma para evitar errores de Ansible
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# 3. Creamos el usuario y le damos permisos sudo
RUN adduser -u $USER_UID --disabled-password --gecos "" $USERNAME \
    && mkdir -p /etc/sudoers.d \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# 4. Cambiamos al usuario no-root
USER $USERNAME
WORKDIR /home/$USERNAME

# 5. Creamos un entorno virtual y le instalamos las herramientas
RUN python3 -m venv /home/$USERNAME/ansible-venv
RUN /home/$USERNAME/ansible-venv/bin/pip install --no-cache-dir ansible-core ansible-lint

# Volvemos a ser ROOT temporalmente para escribir en /usr/local/bin
USER root
RUN for cmd in ansible ansible-config ansible-console ansible-doc ansible-galaxy ansible-inventory ansible-playbook ansible-pull ansible-lint; do \
        ln -s /home/appuser/ansible-venv/bin/$cmd /usr/local/bin/$cmd; \
    done
# Devolvemos el control al usuario
USER $USERNAME

WORKDIR /app
CMD ["sleep", "infinity"]
