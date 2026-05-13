# Limpieza: Migración a solo Debian (eliminar soporte Ubuntu)

El proyecto actualmente solo se usa en Debian 13. Este documento lista todos los cambios
necesarios para eliminar el código muerto de Ubuntu y dejar los roles limpios.

**Regla general:** si un bloque tiene `when: distribution == 'Ubuntu'` → se borra.
Si tiene `when: distribution in ['Ubuntu', 'Debian']` → se simplifica a `when: distribution == 'Debian'`
o se elimina la condición si solo queda Debian.

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

- [ ] Quitar menciones a Ubuntu en las descripciones del proyecto
- [ ] Actualizar ejemplos que comparen Debian vs Ubuntu
- [ ] Sacar lógica específica de versiones Ubuntu (22.04, 24.04)

---

## GRUPO 13 — Documentación raíz
**Tipo:** Actualizar docs para usuarios, sacar Ubuntu como distro soportada.

- [ ] `README.md` — quitar badges, secciones y referencias a Ubuntu (8 refs)
- [ ] `specifications.md` — actualizar compatibilidad y versiones soportadas (3 refs)
- [ ] `TESTING.md` — actualizar matriz de testing (1 ref)
- [ ] `QUICKSTART_TESTING.md` — actualizar guía rápida (1 ref)
- [ ] `roles/funcional/README.md` — limpiar README del rol (11 refs)

---

## GRUPO 14 — Documentación en `docs/`
**Tipo:** Limpiar/decidir qué hacer con docs que mencionan Ubuntu.

Archivos afectados:
- `docs/MOLECULE_GUIDE.md`
- `docs/MULTI_DISTRO_TESTING.md` — ¿se borra entero? ya no es multi-distro
- `docs/PROFILES.md`
- `docs/LESSONS_LEARNED.md`
- `docs/MEJORAS_ROL_FUNCIONAL.md`
- `docs/CHANGELOG_MEJORAS_FUNCIONAL.md`
- `docs/FREELANCE_DEVELOPER.md`
- `docs/TESTING.md`
- `docs/TEST_RUN_NOTES.md`
- `docs/TESTING_IMPLEMENTATION_SUMMARY.md`
- `docs/molecule-multi-distro-example.yml` — ¿borrar? es ejemplo multi-distro

- [ ] Revisar cada uno y actualizar/borrar según corresponda

---

## PENDIENTE — Verificación CI

- [ ] Correr `molecule test` en rol `funcional` y verificar que pasa verde
- [ ] Correr `molecule test` en rol `developer` y verificar que pasa verde
- [ ] Verificar que el workflow de GitHub Actions pasa después de los cambios CI

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
⏳ GRUPO 12  → copilot-instructions    (actualizar contexto IA)
⏳ GRUPO 13  → Docs raíz               (README, specs, testing)
⏳ GRUPO 14  → Docs en docs/           (limpiar guides y notes)
```

Después de cada grupo de código: correr `molecule test` del rol afectado.
Los grupos 12-14 son solo documentación y no requieren validación CI.
