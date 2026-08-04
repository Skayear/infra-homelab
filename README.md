# infra-homelab

Configuracion como codigo de mi homelab: Proxmox VE como hipervisor,
OpenTofu para crear las VMs/LXC, y Ansible para configurar el software
adentro de cada maquina (fisica o virtual).

## Arquitectura

```
notebook (Proxmox VE)              raspberry pi (standalone, sin Proxmox)
├── LXC "databases"                └── Docker
│   └── Postgres + pgvector            └── agente de IA (llama a model-server)
└── VM "model-server"
    └── Ollama (modelos LLM)
```

- **Notebook** corre Proxmox VE y hostea, como VM/LXC, los servicios
  "pesados": el servidor de modelos (Ollama) y las bases de datos.
- **Raspberry Pi** corre el agente de IA. Queda **fuera** del cluster
  Proxmox porque Proxmox VE solo soporta oficialmente x86_64 — en ARM no es
  estable. La Pi se gestiona directo con Ansible (Debian/RPi OS + Docker).
- El repo esta pensado para crecer a 2-3 nodos Proxmox (cluster) si sumas
  mas hardware x86 despues; hoy es un solo nodo.

## Estructura del repo

```
opentofu/          # Crea/destruye VMs y LXC en Proxmox (IaC)
  modules/vm/       # Modulo generico: VM Debian via cloud-init
  modules/lxc/       # Modulo generico: LXC Debian sin privilegios
  main.tf            # Instancia los modulos: LXC "databases", VM "model-server"

ansible/            # Configura el software adentro de cada maquina
  inventory/hosts.yml     # Nodos fisicos fijos: notebook (Proxmox), Raspberry Pi
  inventory/proxmox.yml   # Inventario dinamico: descubre VMs/LXC por tag
  roles/                  # common, proxmox_node, docker, postgres, ollama, ai_agent
  playbooks/               # Uno por grupo de hosts (ver abajo)

docs/proxmox-setup.md   # Paso a paso manual, unico paso no versionado
```

## Orden de ejecucion (de cero)

1. **Instalar Proxmox y crear el token de API** — manual, ver
   [`docs/proxmox-setup.md`](docs/proxmox-setup.md).

2. **Configurar Proxmox mismo con Ansible** (repos, updates del host):

   ```bash
   cd ansible
   ansible-galaxy collection install -r requirements.yml
   # editar inventory/hosts.yml con la IP real de la notebook y de la Pi
   ansible-playbook playbooks/proxmox-nodes.yml
   ```

3. **Crear las VMs/LXC con OpenTofu**:

   ```bash
   cd opentofu
   cp terraform.tfvars.example terraform.tfvars   # completar con tus valores reales
   tofu init
   tofu plan
   tofu apply
   ```

4. **Configurar el software adentro de esas VMs/LXC**, usando el inventario
   dinamico (las descubre solas por el tag que les puso OpenTofu):

   ```bash
   cd ansible
   cp inventory/group_vars/tag_databases/vault.yml.example inventory/group_vars/tag_databases/vault.yml
   ansible-vault encrypt inventory/group_vars/tag_databases/vault.yml
   ansible-playbook -i inventory/proxmox.yml playbooks/databases.yml --ask-vault-pass
   ansible-playbook -i inventory/proxmox.yml playbooks/model-server.yml
   ```

5. **Configurar la Raspberry Pi** (independiente del cluster Proxmox):

   ```bash
   ansible-playbook playbooks/raspberry-pi.yml
   ```

## Pendientes / decisiones abiertas

- El rol `ai_agent` instala **OpenClaw** (https://docs.openclaw.ai) como CLI
  nativa + gateway systemd `--user`, con onboarding no interactivo apuntando
  al Ollama self-hosted de la notebook (`model_server_url`, modelo
  `llama3.1:8b`) en vez de una API cloud paga. No requiere secrets/vault con
  este proveedor. Integraciones de mensajeria (Telegram/WhatsApp/Discord) NO
  estan habilitadas por defecto — son opt-in y de alto acceso, revisar
  `docs.openclaw.ai` antes de activarlas.
- `cores`/`memory` de la VM `model-server` en `opentofu/main.tf` son valores
  de ejemplo — ajustar a los recursos reales de la notebook, dejando margen
  para Proxmox y el LXC de `databases`.
- Si mas adelante la notebook tiene GPU y se quiere pasarla a la VM de
  Ollama (passthrough), eso requiere cambios adicionales en `modules/vm`
  (IOMMU, vendor-reset, etc.) — no esta cubierto todavia.
- Secrets (passwords, tokens) van con `ansible-vault`, nunca en texto plano.
  Ver `ansible/inventory/group_vars/*/vault.yml.example`.
- OpenClaw se evaluo primero por busqueda web y dio senales de granja SEO
  (dominios casi identicos, cifras de popularidad poco creibles), asi que se
  pauso. Se retomo cuando el usuario paso el link oficial
  (`docs.openclaw.ai`); se verifico el repo real en GitHub
  (`github.com/openclaw/openclaw`, org, actividad de commits diaria, ~30
  contribuidores, releases versionados) y el `install.sh` oficial (clona ese
  mismo repo, instala Node.js/dependencias, sin telemetria visible) antes de
  automatizarlo. Los dominios tipo `getopenclaw.ai` de la busqueda original
  parecen sitios oportunistas aprovechando la popularidad del proyecto, no el
  proyecto en si. Pendiente: decidir si se habilita alguna integracion de
  mensajeria (opt-in, no configurada por defecto).
