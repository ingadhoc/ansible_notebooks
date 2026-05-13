# Limpieza: Migración a solo Debian (eliminar soporte Ubuntu)

El proyecto actualmente solo se usa en Debian 13. Este documento lista todos los cambios
necesarios para eliminar el código muerto de Ubuntu y dejar los roles limpios.

**Regla general:** si un bloque tiene `when: distribution == 'Ubuntu'` → se borra.
Si tiene `when: distribution in ['Ubuntu', 'Debian']` → se simplifica a `when: distribution == 'Debian'`
o se elimina la condición si solo queda Debian.

---

## 📊 Estado actual

**Completado** (commit `bd34ddf` + posteriores):
- ✅ Grupos 1-5, 7, 8 — código activo de los roles `funcional` y `developer`
- ✅ Grupo 9 — Molecule converge.yml en 3 roles
- ✅ Grupo 12 — copilot-instructions.md
- ✅ Grupo 13 — Docs raíz (README, specifications, TESTING, QUICKSTART, funcional/README)
- ✅ **Bonus:** fix del callback `community.general.yaml` (removido en 12.0.0) en los 4 molecule.yml
- ✅ Test `make test-funcional` pasa verde

**Pendiente:**
- ⏳ Grupo 10 — `Makefile` (sacar targets `test-ubuntu*`, limpiar `docker-pull-images`)
- ⏳ Grupo 11 — `.github/workflows/molecule.yml` (sacar matriz Ubuntu del CI)
- ⏳ Grupo 14 — Docs en `docs/`:
  - Borrar 2 obsoletos (`MULTI_DISTRO_TESTING.md`, `molecule-multi-distro-example.yml`)
  - Editar 5 activos (`MOLECULE_GUIDE.md`, `TESTING.md`, `FREELANCE_DEVELOPER.md`, `PROFILES.md`, `TEST_RUN_NOTES.md`)
- ⏳ Grupo 6 — `local_dns.yml` (decisión pendiente, dejado a propósito por ahora)
- ⏳ Validación CI: `make test-developer` y `make test-sysadmin`
- ⏳ **Validación end-to-end en PC física o VM con Debian 13 limpio**
  - Molecule (Docker) NO testea GNOME, dconf, branding visual, sessions Xorg, GDM, ni componentes con GUI
  - Es la única forma de validar que el playbook completo funciona en una instalación real
  - Probar los 3 perfiles: `funcional`, `developer`, `sysadmin`

---

## GRUPO 1 — `roles/funcional/vars.yml`
**Tipo:** Borrado puro de variables muertas. Sin riesgo, nada las referencia en Debian.

- [x] Borrar bloque `packages_ubuntu_common`
- [x] Borrar bloque `packages_ubuntu_2204_power`
- [x] Borrar bloque `funcional_gnome_extensions_ubuntu_2204` con su comentario
- [x] Borrar bloque `funcional_gnome_extensions_ubuntu_2404` con su comentario
- [x] Borrar bloque `language_packs_ubuntu`
- [x] Borrar variable `snaps_to_remove` (solo la usaban las tasks snap de Ubuntu)

---

## GRUPO 2 — `roles/funcional/tasks/packages.yml`
**Tipo:** Borrado de tasks que solo corren en Ubuntu. No tocan Debian.

- [x] Borrar task "Instalar paquetes específicos de Ubuntu"
- [x] Borrar task "Verificar si snap está instalado"
- [x] Borrar task "Eliminar programas snap no deseados"

---

## GRUPO 3 — `roles/funcional/tasks/language.yml`
**Tipo:** Borrar task Ubuntu, simplificar condición Debian.

- [x] Borrar task "Instalar paquetes de idioma para Ubuntu"
- [x] Eliminar `when: distribution == 'Debian'` de la task que quedó (innecesario si solo es Debian)
- [x] Renombrar task a "Instalar paquetes de idioma" (sin mención de distro)

---

## GRUPO 4 — `roles/funcional/tasks/fixes.yml`
**Tipo:** Mezcla de borrado y simplificación de condiciones.

- [x] Task "Aplicar aplicaciones favoritas del dock": simplificar `in ['Ubuntu', 'Debian']` → borrar condición de distro
- [x] Borrar task completa "Configurar comportamiento del dock (dash-to-dock, solo Ubuntu)"
- [x] Task "Forzar Xorg": simplificar `when` sacando la rama Ubuntu, renombrar task

---

## GRUPO 5 — `roles/funcional/tasks/gnome.yml`
**Tipo:** Simplificar lógica del set_fact que construye la lista de extensiones.

- [x] Simplificar `set_fact` de extensiones: eliminar las dos condiciones Ubuntu del ternario,
  quedar solo con `funcional_gnome_extensions_common + funcional_gnome_extensions_debian`

---

## GRUPO 6 — `roles/funcional/tasks/local_dns.yml`
**Tipo:** Decisión pendiente — el bloque está deshabilitado en Debian por problemas de conectividad.

El archivo tiene este estado actual:
```yaml
# TEMPORALMENTE DESHABILITADO EN DEBIAN: Causa problemas de conectividad
# TODO: Investigar solución robusta para Debian
when: ansible_facts['distribution'] == 'Ubuntu'   ← bloque entero saltea en Debian
```

- [ ] **Decidir:** ¿se quiere habilitar DNS para Debian en el futuro o se borra el bloque?
  - Si se habilita: resolver el problema de conectividad y cambiar la condición a Debian
  - Si se descarta: borrar el archivo o dejarlo vacío con un comentario explicativo

---

## GRUPO 7 — `roles/developer/tasks/fixes.yml`
**Tipo:** Simplificar condición mixta.

- [x] Task "Establecer aplicaciones favoritas en el dock de GNOME": borrar `in ['Ubuntu', 'Debian']`

---

## GRUPO 8 — `roles/developer/vars.yml`
**Tipo:** Simplificar variable condicional por versión de Ubuntu.

- [x] Simplificar ternario python-venv (`22.04 → python3.10-venv` / `24.04 → python3.12-venv` / `else → python3-venv`) a directamente `python3-venv`

---

## GRUPO 9 — Molecule converge.yml (tests CI)
**Tipo:** Limpiar configuración de tests para que solo testeen Debian.

- [x] `roles/funcional/molecule/default/converge.yml` — sacado ternario Ubuntu, simplificado a lista YAML
- [x] `roles/developer/molecule/default/converge.yml` — sacado ternario Ubuntu, simplificado a lista YAML
- [x] `roles/freelance_developer/molecule/default/converge.yml` — sacado ternario Ubuntu, simplificado a lista YAML

---

## GRUPO 10 — `Makefile`
**Tipo:** Eliminar targets que corren tests contra Ubuntu.

- [ ] Borrar targets `test-ubuntu2404` y `test-ubuntu2204`
- [ ] Limpiar referencias a `docker pull geerlingguy/docker-ubuntu*-ansible`
- [ ] Limpiar comentarios y mensajes `echo` que mencionan Ubuntu
- [ ] Verificar que `make test` solo dispare Debian

---

## GRUPO 11 — `.github/workflows/molecule.yml`
**Tipo:** Limpiar matriz CI para que solo corra contra Debian.

- [ ] Eliminar las distros Ubuntu de la matriz de testing
- [ ] **NO TOCAR:** `runs-on: ubuntu-latest` → ese es el runner OS de GitHub Actions,
  no la distro que se testea. Es Ubuntu por la infra de GitHub, no por nuestro proyecto.

---

## GRUPO 12 — `.github/copilot-instructions.md`
**Tipo:** Actualizar instrucciones para Copilot para reflejar solo-Debian.

- [x] Quitar mención "Debian 12+ and Ubuntu 22.04+" → "Debian 13"
- [x] Reescribir "Debian vs Ubuntu differences" → "Debian version-specific behavior"
- [x] "Manual testing in VirtualBox VMs with Debian/Ubuntu" → "with Debian 13"
- [x] "Debian 12 and Ubuntu 22.04 containers" → "Debian 13 containers"
- [x] "Test distribution-specific logic (Debian vs Ubuntu differences)" → "Test Debian version-specific behavior"

---

## GRUPO 13 — Documentación raíz
**Tipo:** Actualizar docs para usuarios, sacar Ubuntu como distro soportada.

- [x] `README.md` — badge actualizado a "Debian 13", sección "Filosofía" reescrita, secciones de testing multi-distro eliminadas
- [x] `specifications.md` — "Debian-First" → "Debian-Only", plataformas simplificadas
- [x] `TESTING.md` — eliminada la mención a Ubuntu, "Debian 13 (Trixie)" como única distro
- [x] `QUICKSTART_TESTING.md` — comando ejemplo actualizado a "Debian 13"
- [x] `roles/funcional/README.md` — requisitos simplificados, sección "Testing con distribuciones adicionales" eliminada (~80 líneas Ubuntu-específicas)

---

## GRUPO 14 — Documentación en `docs/`
**Tipo:** Limpiar/borrar docs según relevancia.

### Para borrar (obsoletos)
- [ ] `docs/MULTI_DISTRO_TESTING.md` (16 refs) — guía completa multi-distro, ya no aplica
- [ ] `docs/molecule-multi-distro-example.yml` (16 refs) — ejemplo YAML multi-distro

### Para editar (docs activos)
- [ ] `docs/MOLECULE_GUIDE.md` (26 refs) — guía de Molecule
- [ ] `docs/TESTING.md` (4 refs)
- [ ] `docs/FREELANCE_DEVELOPER.md` (2 refs)
- [ ] `docs/PROFILES.md` (1 ref)
- [ ] `docs/TEST_RUN_NOTES.md` (1 ref)

### Dejar como historia (NO tocar — historial del proyecto)
- `docs/CHANGELOG_MEJORAS_FUNCIONAL.md` (5 refs)
- `docs/MEJORAS_ROL_FUNCIONAL.md` (5 refs)
- `docs/TESTING_IMPLEMENTATION_SUMMARY.md` (3 refs)
- `docs/LESSONS_LEARNED.md` (2 refs)

### No tocar (intencional)
- `docs/debian-only-cleanup.md` — es este mismo plan

---

## PENDIENTE — Verificación CI y end-to-end

### Validación con Molecule (Docker, sin GUI)
- [x] Correr `molecule test` en rol `funcional` — pasa verde ✓
- [ ] Correr `molecule test` en rol `developer`
- [ ] Correr `molecule test` en rol `sysadmin`
- [ ] Verificar que el workflow de GitHub Actions pasa después de los cambios CI

### Validación end-to-end (PC física o VM con GUI)
**Imprescindible antes de mergear a main.** Molecule no cubre:
- Configuración de GNOME (dconf, extensiones, atajos)
- Branding (wallpapers, temas, layout del dock)
- Sesiones Xorg/GDM3, AccountsService
- Instalación real de paquetes con GUI (Chrome, VS Code, flameshot, etc.)

- [ ] Probar perfil `funcional` en PC física o VM Debian 13 limpio
- [ ] Probar perfil `developer` en PC física o VM Debian 13 limpio
- [ ] Probar perfil `sysadmin` en PC física o VM Debian 13 limpio
- [ ] Verificar idempotencia: correr el playbook 2 veces, segunda corrida debe ser `changed=0` (excluyendo tareas que tocan tiempo/random)
- [ ] Verificar que GNOME extensiones se instalan correctamente
- [ ] Verificar que Xorg se fuerza correctamente (sesión activa post-reinicio)

---

## Orden sugerido de ejecución

```
✅ GRUPO 1   → vars.yml funcional      (borrado puro, sin riesgo)
✅ GRUPO 2   → packages.yml funcional  (borrar tasks Ubuntu)
✅ GRUPO 3   → language.yml funcional  (borrar task + simplificar)
✅ GRUPO 4   → fixes.yml funcional     (borrar + simplificar Xorg)
✅ GRUPO 5   → gnome.yml funcional     (simplificar set_fact)
✅ GRUPO 7   → fixes.yml developer     (simplificar condición)
✅ GRUPO 8   → vars.yml developer      (simplificar python venv)
⏳ GRUPO 6   → local_dns.yml           (requiere decisión primero)
✅ GRUPO 9   → Molecule converge.yml   (3 archivos de test)
⏳ GRUPO 10  → Makefile                (sacar targets Ubuntu)
⏳ GRUPO 11  → workflows/molecule.yml  (sacar matriz Ubuntu)
✅ GRUPO 12  → copilot-instructions    (actualizar contexto IA)
✅ GRUPO 13  → Docs raíz               (README, specs, testing)
⏳ GRUPO 14  → Docs en docs/           (borrar 2 obsoletos + editar 5 activos)
```

Después de cada grupo de código: correr `molecule test` del rol afectado.
Los grupos 12-14 son solo documentación y no requieren validación CI.

---

## 🚀 Próximos pasos sugeridos

**Orden recomendado para terminar la limpieza:**

1. **Commit de lo hecho ahora** (Grupos 12 + 13) — chunk coherente "docs cleanup raíz + copilot"
   ```bash
   git add .github/copilot-instructions.md README.md specifications.md TESTING.md QUICKSTART_TESTING.md roles/funcional/README.md docs/debian-only-cleanup.md
   git commit -m "docs: remove Ubuntu references from root docs and copilot instructions"
   ```

2. **Grupo 14 — Docs en `docs/`** (también solo texto, sin riesgo)
   - Borrar 2 obsoletos con `git rm`
   - Editar 5 activos
   - Commit aparte: `docs: clean Ubuntu references in docs/ directory`

3. **Grupo 10 — Makefile** (sacar targets Ubuntu)
   - Commit: `chore: remove Ubuntu targets from Makefile`

4. **Grupo 11 — workflows/molecule.yml** (sacar matriz Ubuntu del CI de GitHub Actions)
   - ⚠️ **NO TOCAR** `runs-on: ubuntu-latest` (es el runner OS, no la distro testada)
   - Commit: `ci: remove Ubuntu from molecule test matrix`

5. **Tests Molecule** (Docker, sin GUI)
   ```bash
   make test-developer   # ~10 min
   make test-sysadmin    # ~10 min
   ```

6. **Validación end-to-end en PC física o VM** ⚠️ **IMPRESCINDIBLE**
   - Levantar una VM (VirtualBox/KVM) con **Debian 13 limpio** o usar una notebook formateada
   - Correr el bootstrap completo:
     ```bash
     curl -L -o adhoc-ansible https://raw.githubusercontent.com/ingadhoc/ansible_notebooks/<branch>/launch_project.sh
     chmod +x adhoc-ansible
     sudo ./adhoc-ansible
     ```
   - Probar cada perfil (`funcional`, `developer`, `sysadmin`) y verificar:
     - Sin errores Ansible al correr
     - Idempotencia: segunda corrida con `changed=0`
     - GNOME: extensiones instaladas, atajos funcionando, branding aplicado
     - Sesión Xorg activa después de reiniciar
     - VS Code, Chrome, Docker funcionando

7. **Push de la rama y abrir PR**
   ```bash
   git push -u origin chore/debian-only-cleanup
   gh pr create --title "Migrate to Debian-only support" --body "..."
   ```

8. **Grupo 6 — `local_dns.yml`** — pendiente de decisión funcional (NO bloquea el PR)
