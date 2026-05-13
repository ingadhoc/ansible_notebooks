# Notas de la Primera Ejecución de Tests

## Fecha: 31 de Octubre, 2025

### Problemas Encontrados y Soluciones

#### 1. Molecule no encontraba el rol `funcional`
**Error**: `the role 'funcional' was not found`

**Causa**: Molecule ejecuta desde `roles/funcional/molecule/default/` y no podía encontrar el rol en el path correcto.

**Solución**: Actualizado `molecule.yml` para incluir:
```yaml
provisioner:
  config_options:
    defaults:
      roles_path: ../../../../roles
  env:
    ANSIBLE_ROLES_PATH: ../../../../roles
```

#### 2. Tareas de GNOME fallaban en contenedores Docker
**Error**: `Failed to find required executable "dconf"`

**Causa**: Las tareas que usan `dconf`, `gnome-shell`, y otras herramientas GUI no están disponibles en contenedores Docker sin display.

**Solución**: Agregado condición `when: not (skip_gnome_tasks | default(false))` a todas las tareas que usan dconf:
- `roles/funcional/tasks/ext.yml`
- `roles/funcional/tasks/ui_performance.yml`
- `roles/funcional/tasks/gnome.yml`
- `roles/funcional/tasks/shortcuts.yml`
- `roles/funcional/tasks/branding.yml`
- `roles/funcional/tasks/fixes.yml`
- `roles/funcional/tasks/language.yml`

Y en `converge.yml` se configuró:
```yaml
vars:
  skip_gnome_tasks: true
```

### Estado Actual

✅ **Syntax check**: PASADO
✅ **Container creation**: EXITOSO  
✅ **Prepare phase**: EXITOSO
🔄 **Converge phase**: EN EJECUCIÓN (instalando todos los paquetes del rol funcional)

### Próximos Pasos

1. **Esperar a que termine la ejecución actual** (~10-15 minutos)
2. **Revisar resultados del verify phase** para asegurar que las verificaciones pasan
3. **Ajustar verify.yml** si es necesario basado en lo que realmente se instaló
4. **Documentar tiempo promedio** de ejecución para CI/CD

### Lecciones Aprendidas

- **Contenedores Docker != Máquinas virtuales**: No todo se puede testear en Docker
- **GUI tasks requieren special handling**: Cualquier tarea de GNOME/dconf/gsettings necesita ser condicional
- **Timeouts en CI**: Considerar aumentar timeouts en GitHub Actions debido a instalación de paquetes pesados (Chrome, gcloud, etc.)
- **/etc/resolv.conf en Docker**: El archivo está montado desde el host y no se puede reemplazar. Detectar con `ansible_virtualization_type == 'docker'`

### Archivos Modificados para Testing

#### Tareas con condición `when: not (skip_gnome_tasks | default(false))`:
- `roles/funcional/tasks/ext.yml` - Configuraciones dconf
- `roles/funcional/tasks/ui_performance.yml` - UI performance settings
- `roles/funcional/tasks/gnome.yml` - GNOME extensions y configuraciones
- `roles/funcional/tasks/shortcuts.yml` - Atajos de teclado
- `roles/funcional/tasks/branding.yml` - Fondos de pantalla
- `roles/funcional/tasks/fixes.yml` - Fixes específicos de GNOME
- `roles/funcional/tasks/language.yml` - Configuración de teclado GNOME

#### Tareas con condición para Docker:
- `roles/funcional/tasks/local_dns.yml` - Skip reemplazo de `/etc/resolv.conf` cuando `ansible_virtualization_type == 'docker'`

### Mejoras Futuras

1. **Cachear paquetes** para acelerar tests
2. **Split tests**: Separar tests de packages vs tests de configuración
3. **Mock repositories**: Usar repositorios locales mock para tests más rápidos
4. **Parallel execution**: Roles en paralelo verdadero
