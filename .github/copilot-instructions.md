# Copilot Instructions: Ansible Notebooks

## Project Overview

This is an Ansible-based laptop provisioning system for Adhoc, designed for clean Debian 12+ and Ubuntu 22.04+ installations. It automates complete workstation setup through hierarchical profile-based roles.

## Architecture: Hierarchical Role System

The project uses **role inheritance through Ansible's `meta/main.yml` dependencies**:

- `funcional` (base layer): Core apps and configurations for all Adhoc employees - browsers, basic security, GNOME desktop config
- `developer` → inherits `funcional` + development tools and apps specifically for Adhoc developers (Docker, VS Code, Git, Python, kubectl)
- `sysadmin` → inherits `funcional` + `developer` + additional tools and configurations for Adhoc sysadmins and SRE teams (Terraform, VirtualBox, Helm, NordVPN)
- `deploy` (standalone/fast): Quick installation role with only deployment-essential tools (kubectl, gcloud, terraform) - activated with `--tags deploy` only, designed for deployment-only machines

**Key dependency files:**
- `roles/developer/meta/main.yml` declares `dependencies: [funcional]`
- `roles/sysadmin/meta/main.yml` declares `dependencies: [developer]`
- `local.yml` orchestrates role execution via `target_profile` variable

## Critical Workflows

### Running playbooks
```bash
# Default (funcional)
ansible-playbook local.yml -K --verbose

# Developer profile (runs funcional → developer)
ansible-playbook local.yml -e "profile_override=developer" -K --verbose

# Sysadmin profile (runs funcional → developer → sysadmin)
ansible-playbook local.yml -e "profile_override=sysadmin" -K --verbose

# Deploy-only tools (special standalone role with 'never' tag)
ansible-playbook local.yml --tags "deploy" -K --verbose
```

### Bootstrap workflow
`launch_project.sh` is the entry point for new machines - it installs Ansible, clones the repo, and runs the playbook interactively. It's designed to be downloaded via `curl` and executed with `sudo`.

### Testing changes
- Update collections: `ansible-galaxy install -r collections/requirements.yml`
- Check syntax: `ansible-playbook local.yml --syntax-check`
- Dry-run: `ansible-playbook local.yml -e "profile_override=developer" -K --check`
- Run specific tags: `ansible-playbook local.yml --tags "code,docker" -K`

### Adding a new package installation task
1. **Identify the target role** based on the package purpose (funcional/developer/sysadmin)
2. **Update `vars.yml`**: Add package to appropriate list variable (e.g., `developer_packages_base`, `packages_system`)
3. **Choose installation method**:
   - **Simple apt packages**: Add to existing list in `tasks/packages.yml` or `tasks/packages_dev.yml`
   - **External repository needed**: Create dedicated task file (e.g., `tasks/newtool.yml`)
4. **For external repos**, follow this pattern (see `roles/developer/tasks/code.yml`):
   ```yaml
   - name: Tool | Create GPG keyring directory
     ansible.builtin.file:
       path: /etc/apt/keyrings
       state: directory
       mode: '0755'
   
   - name: Tool | Download and convert GPG key
     ansible.builtin.shell: curl -fsSL <URL> | gpg --dearmor -o /etc/apt/keyrings/tool.gpg
     args:
       creates: /etc/apt/keyrings/tool.gpg
   
   - name: Tool | Add repository
     ansible.builtin.apt_repository:
       repo: "deb [signed-by=/etc/apt/keyrings/tool.gpg] <REPO_URL>"
       state: present
       filename: tool
       update_cache: true
   
   - name: Tool | Install package
     ansible.builtin.apt:
       name: tool-name
       state: present
   ```
5. **Import task in `tasks/main.yml`**: Add `ansible.builtin.import_tasks: newtool.yml` in appropriate order
6. **Tag appropriately**: Use role name tag (e.g., `tags: developer`) or feature-specific tag
7. **Test**: Run playbook with `--check` first, then full run on test VM

## Project Conventions

### File organization
- Each role has: `tasks/main.yml` (orchestrator), `vars.yml` (variables), individual `tasks/*.yml` (feature-specific)
- `tasks/main.yml` imports all feature tasks in sequence (e.g., `packages.yml`, `docker.yml`, `code.yml`)
- Configuration files stored in `files/` directory, Jinja2 templates in `templates/`
- All roles tagged with their profile name (e.g., `tags: developer`, `tags: funcional`)

### Variable patterns
- **User detection**: `remote_regular_user: "{{ ansible_env.SUDO_USER | default(ansible_user) }}"` - critical for running tasks as the actual user when using `sudo`
- **Distribution-specific logic**: Use `ansible_facts['distribution']` and `ansible_facts['distribution_version']` for Debian vs Ubuntu differences
- **Package exclusions**: `packages_exclude_debian_13` pattern for distro-specific package availability
- Variables prefixed with role name: `developer_*`, `funcional_*`, `sysadmin_*`

### Task structure patterns
```yaml
# Standard block with become user switching
- name: Feature | Description
  tags: feature_name
  become: true
  become_user: "{{ remote_regular_user }}"
  block:
    - name: Specific task
      ansible.builtin.module_name:
        # ...
```

### Idempotency for package/extension management
Use "check-then-install" pattern (see `roles/developer/tasks/code.yml`):
1. Query currently installed items: `code --list-extensions`
2. Filter to only missing items
3. Install only what's needed

### Repository management
- External repos added via GPG keys in `/etc/apt/keyrings/`
- Use `creates:` parameter for idempotent shell commands
- Always set `update_cache: true` when adding repos

### The "deploy" role special case
- Has `tags: [deploy, never]` in `local.yml` - means it ONLY runs when explicitly tagged
- Reuses tasks from other roles via relative paths: `../roles/funcional/tasks/kubectl.yml`
- Used for lightweight tooling on deployment-only machines

## Configuration

- **ansible.cfg**: Uses local connection, custom callbacks (`timer`, `profile_tasks`, `profile_roles`) for performance monitoring
- **hosts**: Single `[laptop]` group with `localhost` and local connection
- **collections/requirements.yml**: Community modules (community.general, ansible.posix, community.crypto)

## Anti-patterns to avoid

- Don't use `snap` packages - project philosophy prioritizes apt/manual installs over Canonical's snap ecosystem
- Don't hardcode usernames - always use `remote_regular_user` variable
- Don't skip tags on standard tasks - tag strategy relies on profile names and feature names
- Don't create circular dependencies between roles - hierarchy is strictly one-directional
- Don't use `python -c` in tasks - use proper Ansible modules for Python operations

## Testing Strategy (Progressive Approach)

### Current state
Manual testing in VirtualBox VMs with clean Debian/Ubuntu installations.

### Planned automated testing with Molecule
**Goal**: Systematize testing to avoid exclusive reliance on manual VirtualBox testing.

**Progressive implementation approach:**
1. **Phase 1 - Basic Molecule setup**:
   - Install Molecule: `pip install molecule molecule-plugins[docker]`
   - Create initial scenario for `funcional` role: `molecule init scenario -r funcional`
   - Configure `molecule/default/molecule.yml` with Debian 12 and Ubuntu 22.04 containers
   - Write basic verification tests in `molecule/default/verify.yml` (check key packages installed)

2. **Phase 2 - Expand coverage**:
   - Add scenarios for `developer` and `sysadmin` roles
   - Create test suites verifying:
     - Package installation
     - Service states (Docker, SSH)
     - File/directory presence and permissions
     - User configurations (Git, VS Code extensions)
   - Test distribution-specific logic (Debian vs Ubuntu differences)

3. **Phase 3 - CI/CD integration**:
   - Set up GitHub Actions workflow (`.github/workflows/molecule.yml`)
   - Run Molecule tests on pull requests
   - Test matrix: multiple distros and versions
   - Cache Docker images and Ansible collections for speed

4. **Phase 4 - Advanced scenarios**:
   - Test role dependencies and inheritance
   - Verify idempotency (run playbook twice, second run should have no changes)
   - Test tag-based execution (`--tags deploy`)
   - Profile-specific testing (`profile_override` variable)

**Key testing considerations:**
- Use Docker for fast container-based testing (not full VMs)
- Privileged containers may be needed for systemd and some package operations
- Mock external dependencies where possible (repositories, downloads)
- Keep VirtualBox manual testing for final integration validation

## Key files for reference

- `local.yml`: Main playbook orchestration logic
- `roles/{profile}/tasks/main.yml`: Entry points showing feature organization
- `roles/{profile}/vars.yml`: Profile-specific variable definitions
- `launch_project.sh`: Bootstrap script pattern for understanding initial setup flow
