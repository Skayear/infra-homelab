# Setup inicial de Proxmox (manual, una sola vez)

Esto es lo unico que se hace a mano, antes de que OpenTofu/Ansible existan
para el cluster: instalar el hipervisor y crear el usuario/token de API que
van a usar OpenTofu y el inventario dinamico de Ansible.

## 1. Instalar Proxmox VE en la notebook

Descargar el ISO de Proxmox VE desde proxmox.com/downloads e instalarlo
directo sobre el disco (reemplaza el SO actual de la notebook). Notas para
notebook-como-servidor:

- En la BIOS/UEFI, deshabilitar el suspend/hibernate automatico.
- En `/etc/systemd/logind.conf`, setear `HandleLidSwitch=ignore` y
  `HandleLidSwitchExternalPower=ignore` para que no se suspenda al cerrar la tapa.
- Si solo tiene una placa de red, la vas a necesitar para management y para
  las VMs a la vez (el bridge vmbr0 default ya comparte esto, no requiere nada
  extra en un homelab chico).

## 2. Crear el usuario y token de API para automatizacion

Por SSH en el nodo Proxmox:

```bash
# Usuario dedicado para terraform/ansible (no usar root en texto plano)
pveum user add terraform@pve
pveum role add Terraform -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Pool.Allocate SDN.Use"
pveum aclmod / -user terraform@pve -role Terraform
pveum user token add terraform@pve terraform --privsep 0
```

El ultimo comando imprime el token completo (`terraform@pve!terraform=uuid`)
**una sola vez** — copialo ya a tu gestor de secretos. Ese valor va en
`opentofu/terraform.tfvars` (`proxmox_api_token`) y en las variables de
entorno que usa `ansible/inventory/proxmox.yml`.

## 3. Confirmar acceso

```bash
curl -k -H "Authorization: PVEAPIToken=terraform@pve!terraform=<uuid>" \
  https://<ip-notebook>:8006/api2/json/version
```

Si devuelve JSON con la version de Proxmox, el token funciona.

## 4. A partir de aca, todo versionado

- `opentofu/` crea las VMs/LXC.
- `ansible/playbooks/proxmox-nodes.yml` configura el host Proxmox en si
  (repos, updates).
- `ansible/playbooks/{databases,model-server}.yml` configuran lo que corre
  adentro de cada VM/LXC.
