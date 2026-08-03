# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Infrastructure-as-code for a home Proxmox VE homelab: OpenTofu provisions VMs/LXC on Proxmox, and Ansible configures the software inside every machine (physical or virtual). A prior Kubernetes/ArgoCD bootstrap was deliberately removed in favor of this Proxmox-based stack — don't reintroduce Helm/ArgoCD/K8s manifests here without the user explicitly asking for it.

## Commands

### OpenTofu (`opentofu/`)
```bash
cd opentofu
cp terraform.tfvars.example terraform.tfvars   # fill with real values, gitignored, holds the Proxmox API token
tofu init
tofu fmt -recursive -check   # run before committing any .tf change
tofu plan
tofu apply
```

### Ansible (`ansible/`)
```bash
cd ansible
ansible-galaxy collection install -r requirements.yml   # once, and after adding collections

# Static inventory (physical/fixed hosts: Proxmox node, Raspberry Pi)
ansible-playbook playbooks/proxmox-nodes.yml
ansible-playbook playbooks/raspberry-pi.yml

# Dynamic inventory (VMs/LXC on Proxmox, discovered by tag) — needs
# PROXMOX_URL / PROXMOX_TOKEN_ID / PROXMOX_TOKEN_SECRET env vars set
ansible-playbook -i inventory/proxmox.yml playbooks/databases.yml --ask-vault-pass
ansible-playbook -i inventory/proxmox.yml playbooks/model-server.yml

# Syntax check for a single playbook
ansible-playbook <playbook>.yml --syntax-check
```
There's no test suite or linter configured in this repo; `tofu fmt -check` and `--syntax-check` are the closest things to CI gates.

## Architecture

- **Two-phase, ordered deployment**: OpenTofu creates a guest → Ansible (via the dynamic inventory) configures what runs inside it. Ansible can't configure a guest OpenTofu hasn't created yet, and the dynamic inventory can't see a guest that lacks the right Proxmox tag. `docs/proxmox-setup.md` covers the one manual, unversioned step before any of this: installing Proxmox VE and creating the `terraform@pve` API token that both OpenTofu and the dynamic inventory authenticate with.

- **The Raspberry Pi is intentionally NOT a Proxmox node.** Proxmox VE only officially supports x86_64; the Pi runs plain Debian/Raspberry Pi OS + Docker and is configured directly by Ansible as a standalone host (`inventory/hosts.yml`, group `raspberry_pi`), outside the Proxmox-managed fleet. Don't add the Pi to `opentofu/` or treat it as a Proxmox guest.

- **Two Ansible inventories, not one:**
  - `inventory/hosts.yml` — static, for physical/fixed hosts (Proxmox nodes, Raspberry Pi).
  - `inventory/proxmox.yml` — dynamic, via the `community.general.proxmox` plugin. It groups guests by their Proxmox tag using `keyed_groups` (tag `databases` → Ansible group `tag_databases`, tag `model_server` → `tag_model_server`). If a guest's `tags` in `opentofu/main.tf` changes, the corresponding playbook's `hosts:` line under `ansible/playbooks/` must be updated to match, or Ansible will simply find nothing to configure.

- **`opentofu/modules/vm` and `opentofu/modules/lxc`** are the two reusable provisioning primitives, instantiated in `opentofu/main.tf`:
  - `vm`: imports the official Debian cloud qcow2 image via `proxmox_virtual_environment_download_file` (content_type `import`) and boots it with cloud-init — no manual template step needed.
  - `lxc`: downloads a Debian vztmpl template and creates an unprivileged container.
  - Both use the `bpg/proxmox` provider, which changes its resource schema fairly often between versions; if `tofu plan` reports unknown attributes, check the pinned version in `opentofu/providers.tf` against current provider docs before assuming the module code is wrong.

- **Service placement**: heavy services (Postgres+pgvector, Ollama) run in Proxmox guests on the notebook (LXC `databases`, VM `model-server`); the AI agent itself runs on the Raspberry Pi (`roles/ai_agent`) and reaches Ollama over the network via `model_server_url` in `inventory/group_vars/raspberry_pi.yml`. The `ai_agent` role currently deploys **n8n** as a placeholder (chosen for being lightweight and Pi-friendly) — swap the image/role when the real agent framework is decided, per the open item in the README.

- **Secrets** are ansible-vault encrypted, never plaintext: `ansible/inventory/group_vars/*/vault.yml` is gitignored, `vault.yml.example` is the committed template. Same pattern applies to `opentofu/terraform.tfvars` (gitignored, holds the Proxmox API token) vs. the committed `terraform.tfvars.example`.

- The cluster is designed to grow from the current single Proxmox node (the notebook) to 2-3 nodes if more x86 hardware is added later — keep that in mind when hardcoding node names (`var.proxmox_node` is already parameterized for this).
