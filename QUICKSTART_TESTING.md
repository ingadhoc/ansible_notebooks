# 🚀 Quick Start - Testing con Molecule

## Para empezar AHORA mismo (5 minutos)

### 1. Setup inicial (una sola vez)

```bash
# Ejecutar el script de setup automático
./setup-testing.sh
```

Esto instalará todo lo necesario (Molecule, Ansible, colecciones, etc.)

### 2. Activar entorno virtual

```bash
source .venv/bin/activate
```

### 3. Ejecutar tu primer test

```bash
# Test del rol funcional en Debian 12 y Ubuntu 22.04
./test-role.sh funcional
```

¡Eso es todo! 🎉

---

## Comandos más útiles

```bash
# Verificar que tienes todo instalado
./test-role.sh --check

# Solo ejecutar linting (rápido)
./test-role.sh --lint

# Test de todos los roles
./test-role.sh all
```

---

## Si algo falla

### Docker no responde
```bash
sudo systemctl start docker
sudo usermod -aG docker $USER
# Cerrar sesión y volver a entrar
```

### Dependencias faltantes
```bash
pip install -r requirements-dev.txt
ansible-galaxy install -r collections/requirements.yml
```

---

## Siguientes pasos

1. **Lee la documentación completa**: `cat TESTING.md`
2. **Agrega tests a otros roles**: `cat docs/MOLECULE_GUIDE.md`
3. **Revisa el resumen de implementación**: `cat docs/TESTING_IMPLEMENTATION_SUMMARY.md`

---

## Workflow típico de desarrollo

```bash
# 1. Activar venv
source .venv/bin/activate

# 2. Hacer cambios en un rol
vim roles/funcional/tasks/packages.yml

# 3. Ejecutar tests
./test-role.sh funcional

# 4. Si falla, debuggear
cd roles/funcional
molecule converge  # Re-ejecutar sin destruir contenedor
molecule login     # Entrar al contenedor para investigar

# 5. Cuando funcione, commit
git add -A
git commit -m "Add new package to funcional role"
git push

# 6. GitHub Actions ejecutará tests automáticamente
```

---

## Tips Pro

- **Desarrollo iterativo**: Usa `molecule converge` en lugar de `molecule test` para iterar más rápido (no destruye el contenedor)
- **Debugging**: `molecule login` te da shell dentro del contenedor
- **Ver todo**: `molecule --debug test` muestra logs completos
- **Mantener contenedor**: `molecule test --destroy=never` útil cuando falla

---

## Recursos

- 📖 Documentación detallada: [TESTING.md](TESTING.md)
- 🔧 Guía para crear tests: [docs/MOLECULE_GUIDE.md](docs/MOLECULE_GUIDE.md)
- 📋 Resumen de implementación: [docs/TESTING_IMPLEMENTATION_SUMMARY.md](docs/TESTING_IMPLEMENTATION_SUMMARY.md)
- 🌐 Molecule docs: https://molecule.readthedocs.io/
