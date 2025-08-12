# Usamos la base oficial de Debian Bookworm Slim
FROM debian:bookworm-slim

# Definimos los argumentos para el usuario
ARG USERNAME=appuser
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Configuramos el entorno para que no sea interactivo
ENV DEBIAN_FRONTEND=noninteractive

# 1. Como ROOT, instalamos TODAS las dependencias del sistema de una vez
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Herramientas básicas
    git \
    sudo \
    ssh-client \
    # Añadimos gnupg para la firma de commits
    gnupg \
    # Herramientas para Python y Ansible
    python3-venv \
    python3-pip \
    # Herramienta para configurar el idioma (locale)
    locales \
    && rm -rf /var/lib/apt/lists/*

# 2. Configuramos el locale para evitar errores de Ansible
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

# 5. Creamos un entorno virtual dedicado y le instalamos las herramientas
RUN python3 -m venv /home/$USERNAME/ansible-venv
RUN /home/$USERNAME/ansible-venv/bin/pip install --no-cache-dir ansible-core ansible-lint

# 6. Exponemos la ruta al PATH de forma global
ENV PATH="/home/appuser/ansible-venv/bin:$PATH"

# Volvemos al directorio de trabajo de la aplicación
WORKDIR /app

CMD ["sleep", "infinity"]
