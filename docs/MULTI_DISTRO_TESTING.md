# Guía de Testing Multi-Distribución

Esta guía complementa la documentación principal de Molecule y explica cómo ejecutar el rol `funcional` contra múltiples imágenes de Debian y Ubuntu.

## Objetivos

- Verificar compatibilidad del rol en versiones estables y en testing
- Reducir regresiones específicas de distribución
- Documentar las limitaciones y tiempos de ejecución esperados

## Plataformas Recomendadas

| Distribución | Estado | Notas |
|--------------|--------|-------|
| Debian 12 (Bookworm) | ✅ Producción | Plataforma base, siempre habilitada |
| Ubuntu 22.04 LTS (Jammy) | ✅ Producción | Segunda plataforma por defecto |
| Ubuntu 24.04 LTS (Noble) | ✅ Recomendado | Agregar para validar LTS más reciente |
| Debian 13 (Trixie) | 🟡 Experimental | Imagen puede no estar disponible, algunos paquetes faltan |

## Activar nuevas plataformas en Molecule

1. Edita `roles/funcional/molecule/default/molecule.yml`.
2. Descomenta los bloques correspondientes a Debian 13 o Ubuntu 24.04 (o agrega nuevos basados en el ejemplo).
3. Ajusta `molecule/default/prepare.yml` si la distribución necesita paquetes adicionales.

Ejemplo rápido (ver archivo completo en `docs/molecule-multi-distro-example.yml`):

```yaml
platforms:
  - name: debian12-funcional
    image: geerlingguy/docker-debian12-ansible:latest
    # ...configuración...

  - name: ubuntu2204-funcional
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    # ...configuración...

  - name: ubuntu2404-funcional
    image: geerlingguy/docker-ubuntu2404-ansible:latest
    # ...configuración...
```

## Ejecución selectiva por plataforma

```bash
# Lista las plataformas disponibles
cd roles/funcional
molecule list

# Ejecuta solo en Ubuntu 24.04
docker pull geerlingguy/docker-ubuntu2404-ansible:latest
molecule converge --platform-name ubuntu2404-funcional
molecule verify --platform-name ubuntu2404-funcional
molecule destroy --platform-name ubuntu2404-funcional
```

## Uso del Makefile

El `Makefile` incluye atajos para los escenarios más comunes:

```bash
make test-debian13     # Ejecuta converge + verify sobre Debian 13
make test-ubuntu2404   # Ejecuta converge + verify sobre Ubuntu 24.04
make test-all-distros  # Ejecuta la matriz completa configurada en molecule.yml
make list-platforms    # Lista plataformas disponibles
make docker-pull-images # Descarga imágenes docker necesarias
```

## Consideraciones

- **Tiempo:** cada plataforma adicional suma ~5-10 minutos a la ejecución completa.
- **Caching:** usa `make docker-pull-images` para evitar descargas durante CI.
- **Disponibilidad:** algunas imágenes (especialmente Debian testing) pueden no existir en Docker Hub.
- **Paquetes:** si un paquete falta en Debian 13, agrégalo a `packages_exclude_debian_13`.
- **Logs:** cuando una plataforma falla, revisa los registros correspondientes en `.cache/molecule/` o los artifacts de GitHub Actions.

## Buenas Prácticas

1. Deja solo Debian 12 + Ubuntu 22.04 habilitados por defecto para mantener un feedback rápido.
2. Activa matrices extendidas (`debian13`, `ubuntu2404`) en branches de release o pruebas puntuales.
3. Documenta cualquier incompatibilidad detectada en `docs/CHANGELOG_MEJORAS_FUNCIONAL.md` o en la sección de troubleshooting.
4. Ejecuta `molecule test --destroy=never` al depurar; así puedes entrar al contenedor con `molecule login`.

## Próximos Pasos Sugeridos

- Agregar escenarios dedicados (`molecule/extended/`) para matrices completas
- Integrar pruebas extendidas en GitHub Actions bajo un workflow opcional
- Investigar el uso de cachés de APT (apt-cacher-ng) para acelerar entornos experimentales
