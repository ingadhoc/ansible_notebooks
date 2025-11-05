# Rol: funcional

## Descripción
Rol base para estaciones de trabajo de Adhoc. Instala y configura las aplicaciones y configuraciones esenciales para todos los empleados de la empresa.

## Responsabilidades
- Instalación de paquetes de sistema básicos
- Configuración de herramientas cloud (gcloud, kubectl)
- Instalación de navegadores (Chrome)
- Configuración de seguridad (UFW, fail2ban, SSH hardening)
- Configuración de GNOME Desktop
- Branding corporativo
- Usuario administrativo `sysadmin`
- Configuración de DNS con DoT

## Requisitos
- Debian 12+ o Ubuntu 22.04+
- Python 3.10+
- Conexión a internet para descargar paquetes

## Variables Importantes

### Paquetes
- `packages_system`: Paquetes de sistema esenciales
- `packages_apps`: Aplicaciones de usuario
- `packages_exclude_debian_13`: Paquetes que no están en Debian 13

### Seguridad
- Usuario `sysadmin` con UID 499
- SSH hardening (sin autenticación por contraseña)
- Firewall UFW configurado (denegar entrada, permitir salida)

### DNS
Servidores DNS configurados en `/etc/systemd/resolved.conf`:
- DNS primarios: 8.8.8.8, 1.1.1.1
- DNS secundarios: 8.8.4.4, 1.0.0.1
- DNSOverTLS: habilitado

## Tags Disponibles
- `funcional`: Ejecuta todo el rol
- `packages_funcional`: Solo paquetes de sistema
- `gcloud`: Solo instalación de gcloud SDK
- `kubectl`: Solo instalación de kubectl
- `chrome`: Solo instalación de Google Chrome
- `security`: Solo configuración de seguridad

## Estructura de Tasks

```
tasks/
├── main.yml                 # Orquestador principal
├── packages.yml             # Paquetes de sistema
├── gcloud.yml              # Google Cloud SDK
├── kubectl.yml             # Kubernetes CLI
├── adhoccli.yml            # CLI interna de Adhoc
├── browsers.yml            # Navegadores (Chrome)
├── ext.yml                 # Extensiones GNOME
├── gnome.yml               # Configuraciones GNOME
├── language.yml            # Idioma y locale
├── shortcuts.yml           # Atajos de teclado
├── branding.yml            # Branding corporativo
├── ui_performance.yml      # Optimizaciones UI
├── security.yml            # Seguridad (UFW, fail2ban)
├── user_sysadmin.yml       # Usuario sysadmin
├── fixes.yml               # Fixes específicos de distro
└── local_dns.yml           # Configuración DNS
```

## Testing

### Tests por defecto (Debian 12 + Ubuntu 22.04)

#### Ejecutar tests completos
```bash
cd roles/funcional
molecule test
```

#### Workflow de desarrollo iterativo
```bash
# Una vez al inicio
molecule create
molecule prepare

# Iterar: editar → probar
molecule converge
molecule converge  # Verificar idempotencia

# Validar
molecule verify

# Limpiar
molecule destroy
```

#### Ejecutar solo tags específicos
```bash
molecule converge -- --tags chrome
molecule converge -- --tags gcloud,kubectl
```

### Testing con distribuciones adicionales (Debian 13, Ubuntu 24.04)

Para probar con más distribuciones, puedes agregar plataformas temporalmente a `molecule.yml`:

```yaml
platforms:
  # Existentes
  - name: debian12-funcional
    image: geerlingguy/docker-debian12-ansible:latest
    # ... configuración ...
  
  - name: ubuntu2204-funcional
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    # ... configuración ...
  
  # ⬇️ NUEVAS - Agregar según necesidad
  - name: debian13-funcional
    image: geerlingguy/docker-debian13-ansible:latest
    command: ""
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
    privileged: true
    pre_build_image: true
    tmpfs:
      - /run
      - /tmp
  
  - name: ubuntu2404-funcional
    image: geerlingguy/docker-ubuntu2404-ansible:latest
    command: ""
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
    privileged: true
    pre_build_image: true
    tmpfs:
      - /run
      - /tmp
```

**Notas importantes**:
- ⚠️ Debian 13 puede no tener todas las imágenes Docker listas
- ⚠️ Algunos paquetes pueden no estar disponibles (ver `packages_exclude_debian_13` en vars.yml)
- 💡 Ubuntu 24.04 LTS es estable y bien soportado
- 💡 Verifica disponibilidad de imágenes en [Docker Hub - geerlingguy](https://hub.docker.com/u/geerlingguy)

#### Testing rápido con una distro específica

```bash
# Crear solo un contenedor específico
molecule create --platform-name debian13-funcional

# Converge en esa plataforma
molecule converge --platform-name debian13-funcional

# Verificar
molecule verify --platform-name debian13-funcional

# Destruir
molecule destroy --platform-name debian13-funcional
```

#### Matrix testing en CI/CD

Para GitHub Actions, edita `.github/workflows/molecule.yml`:

```yaml
strategy:
  matrix:
    distro:
      - debian12
      - debian13      # ⬅️ Agregar
      - ubuntu2204
      - ubuntu2404    # ⬅️ Agregar
```

**Tiempo estimado de testing**:
- 2 distros (actual): ~15-20 minutos
- 4 distros (matriz completa): ~30-40 minutos

**Recomendación**: Mantener 2 distros por defecto (Debian 12 + Ubuntu 22.04) para desarrollo rápido. Ejecutar matriz completa solo en:
- Pull Requests importantes
- Releases
- Validación trimestral

## Optimizaciones Aplicadas

### Idempotencia
- Verificación con `stat` antes de descargar archivos
- Verificación de repositorios antes de agregarlos
- Actualización de cache APT solo cuando es necesario
- Condicionales para evitar re-ejecución de comandos

### Performance
- Update de cache APT una sola vez al inicio
- Instalación de paquetes en lotes
- Skip de tasks GNOME en entornos sin GUI (Docker)

### Compatibilidad Docker
- Skip de configuraciones GNOME con `skip_gnome_tasks`
- Skip de configuración DNS con `skip_dns_config`
- Handlers con `failed_when: false` para servicios opcionales

## Tiempos de Ejecución (aproximados)

- Primera ejecución completa: ~4 minutos
- Segunda ejecución (idempotencia): ~2 minutos
- Test completo (Molecule): ~15-20 minutos

## Dependencias Externas
- Google Cloud SDK repository
- Google Chrome repository
- Docker registry (geerlingguy) para tests

## Mantenimiento

### Actualizar versiones de paquetes
Editar `vars.yml` y actualizar las listas de paquetes.

### Agregar nuevos paquetes
1. Agregar a la lista apropiada en `vars.yml`
2. Actualizar test de verificación en `molecule/default/verify.yml`
3. Ejecutar `molecule test` para validar

### Modificar configuraciones
1. Editar el archivo task correspondiente en `tasks/`
2. Asegurar idempotencia con verificaciones previas
3. Validar con `molecule converge` dos veces consecutivas
4. Verificar `changed=0` en la segunda ejecución

## Troubleshooting

### Problema: Tests fallan en Docker
**Causa**: Tasks GNOME intentan ejecutarse sin GUI disponible  
**Solución**: Ya implementado con `skip_gnome_tasks: true` en converge.yml

### Problema: Idempotencia falla en repositorios
**Causa**: `apt_repository` reporta changed aunque el repo exista  
**Solución**: Verificar existencia del archivo `.list` antes con `stat`

### Problema: Servicios fallan en Docker
**Causa**: systemd limitado en contenedores  
**Solución**: Usar `failed_when: false` en handlers o verificar `LoadState` en lugar de `state: started`
