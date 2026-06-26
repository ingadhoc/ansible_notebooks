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
- Debian 13 (Trixie)
- Python 3.10+
- Conexión a internet para descargar paquetes

## Variables Importantes

### Paquetes
- `funcional_packages_system`: Paquetes de sistema esenciales
- `packages_apps`: Aplicaciones de usuario
- `funcional_packages_exclude_debian_13`: Paquetes que no están en Debian 13

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

Los tests corren sobre **Debian 13 (Trixie)** con Molecule + Docker. Atajo:
`./test-role.sh funcional` desde la raíz.

El flujo de trabajo, troubleshooting y cómo agregar tests están documentados en
**[docs/TESTING.md](../../docs/TESTING.md)**.

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
Editar `vars/main.yml` y actualizar las listas de paquetes.

### Agregar nuevos paquetes
1. Agregar a la lista apropiada en `vars/main.yml`
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
**Causa**: `get_url` de la clave GPG reporta changed en cada corrida  
**Solución**: `stat` guard sobre el keyring + escribir el `.sources` deb822 con
`copy` (idempotente por contenido). Ver [specifications.md](../../specifications.md) §3.1

### Problema: Servicios fallan en Docker
**Causa**: systemd limitado en contenedores  
**Solución**: Usar `failed_when: false` en handlers o verificar `LoadState` en lugar de `state: started`
