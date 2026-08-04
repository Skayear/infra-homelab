# Setup del pipeline CI/CD (manual, una sola vez)

El pipeline usa un runner self-hosted de GitHub Actions porque necesita
llegar por red a la API de Proxmox y por SSH a los hosts del homelab
(GitHub-hosted runners no tienen esa visibilidad). Hay un problema de
huevo-y-gallina: el runner mismo se crea con OpenTofu/Ansible, pero todavia
no existe un runner que corra ese OpenTofu/Ansible. Por eso el bootstrap
inicial se hace a mano, desde tu maquina, igual que el setup de Proxmox en
`docs/proxmox-setup.md`.

## 1. Generar el keypair SSH dedicado del runner

No reutilizar tu clave personal: el runner necesita la suya propia para que
quede claro (y sea revocable) que conexiones vienen del pipeline.

```bash
ssh-keygen -t ed25519 -f ci-runner-key -C "ci-runner@infra-homelab" -N ""
```

- La **publica** (`ci-runner-key.pub`) va en
  `ansible/inventory/group_vars/all.yml` (`ssh_authorized_keys`), en texto
  plano, commiteada normalmente.
- La **privada** (`ci-runner-key`) va en
  `ansible/inventory/group_vars/tag_ci_runner/vault.yml`
  (`github_runner_ssh_private_key`), cifrada con `ansible-vault`. Nunca se
  commitea en texto plano ni se sube a GitHub.

## 2. Crear el Personal Access Token para registrar el runner

En GitHub: Settings → Developer settings → Personal access tokens.

- Fine-grained: scope al repo `Skayear/infra-homelab`, permiso
  "Administration: Read and write".
- Classic (alternativa mas simple): scope `repo`.

Este token **no** se usa para nada mas que pedir un registration-token
efimero via la API; no queda persistido en el runner. Va en
`ansible/inventory/group_vars/tag_ci_runner/vault.yml`
(`github_runner_pat`).

```bash
cd ansible/inventory/group_vars/tag_ci_runner
cp vault.yml.example vault.yml
vim vault.yml   # completar github_runner_pat y github_runner_ssh_private_key
ansible-vault encrypt vault.yml
```

## 3. Crear la LXC del runner y configurarlo

Desde tu maquina (con `terraform.tfvars` ya completado, ver
`docs/proxmox-setup.md`):

```bash
cd opentofu
tofu apply   # crea la LXC "ci-runner" ademas de lo que ya existia

cd ../ansible
ansible-playbook -i inventory/proxmox.yml playbooks/ci-runner.yml --ask-vault-pass
```

Confirmar que el runner aparece "Idle" en GitHub: repo → Settings → Actions
→ Runners.

## 4. Secrets y variables del repo

Con el runner ya activo, cargar lo que necesitan los workflows
(`.github/workflows/plan.yml`, `apply.yml`). Secrets = valores sensibles;
Variables = no sensibles (queda mas legible en los logs).

```bash
gh secret set PROXMOX_URL            # ej: https://192.168.1.10:8006/
gh secret set PROXMOX_API_TOKEN      # el mismo terraform@pve!terraform=uuid
gh secret set PROXMOX_TOKEN_ID       # ej: terraform@pve!terraform (usado por el inventario dinamico)
gh secret set PROXMOX_TOKEN_SECRET   # el uuid solo
gh secret set ANSIBLE_VAULT_PASSWORD # password de ansible-vault

gh variable set PROXMOX_NODE --body "pve-notebook"
gh variable set NETWORK_GATEWAY --body "192.168.1.1"
gh variable set SSH_PUBLIC_KEY --body "ssh-ed25519 AAAA... tu-clave-publica"
```

## 5. Proteger el apply con aprobacion manual

`apply.yml` corre bajo el environment `production`. Sin configurarlo, un
`workflow_dispatch` se ejecuta directo sin pedirle permiso a nadie — este
paso es el que realmente lo convierte en manual-con-aprobacion:

Repo → Settings → Environments → New environment → `production` →
"Required reviewers" → agregarte a vos mismo (o a quien corresponda).

## 6. Uso normal, de ahi en adelante

- Cada PR que toque `opentofu/` o `ansible/` dispara `plan.yml` solo (tofu
  plan + ansible --check), automatico, de solo lectura.
- Para aplicar de verdad: Actions → "Apply (manual)" → Run workflow → elegir
  el `target` → aprobar cuando lo pida el environment `production`.
- Si actualizas `ansible/roles/github_runner` o necesitas re-registrar el
  runner (rotacion del PAT, cambio de labels, etc.), volves a correr
  `ansible-playbook -i inventory/proxmox.yml playbooks/ci-runner.yml` a mano
  desde tu maquina (no desde el pipeline mismo).
