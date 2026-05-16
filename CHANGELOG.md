# Changelog

Registro de cambios relevantes del proyecto. Formato basado en [Keep a Changelog](https://keepachangelog.com/).

---

## [2026-05-16]

### Devcontainer

- Corregido `ansible.python.interpreterPath` para apuntar al venv real (`/home/appuser/ansible-venv/bin/python3`) en lugar del Python del sistema
- `postCreateCommand` ahora instala `requirements-dev.txt` (molecule, pytest-testinfra, etc.) y corre `pre-commit install` además de `ansible-galaxy`
- Agregadas extensiones: `shellcheck`, `markdownlint`, `ms-python.python`
- Activada validación y autocompletado de módulos Ansible en el editor
- Agregadas variables de entorno `ANSIBLE_FORCE_COLOR` para output coloreado en terminal
- Agregado forwarding del SSH agent del host al container (necesario para conectar a hosts remotos)
- Alineado el editor con las reglas de pre-commit: `trimTrailingWhitespace`, `insertFinalNewline`

---

## [2025-11-01]

### Rol `funcional` — mejoras generales

- Idempotencia completa: segunda ejecución sin cambios
- Eliminado módulo deprecado `apt_key`; migrado a GPG keyrings modernos
- Variables de URLs externas centralizadas en `vars.yml`
- Cobertura de tests ampliada: 22 → 29 verificaciones
- Agregados handlers para UFW, fail2ban, sshd, systemd-resolved, GDM
- Migración `google-cloud-sdk` → `google-cloud-cli`
- Pre-commit hooks configurados (yamllint, ansible-lint, detect-secrets, markdownlint)
- Makefile con 20+ comandos de desarrollo y testing
- GitHub Actions con caché de pip y colecciones (~30% más rápido en CI)

Ver detalle técnico en [docs/CHANGELOG_MEJORAS_FUNCIONAL.md](docs/CHANGELOG_MEJORAS_FUNCIONAL.md).
