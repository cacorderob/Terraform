# Infraestructura Azure — Terraform Cloud

Proyecto Terraform para desplegar infraestructura base en Azure:
VM Windows Server 2025 + SQL Server + Networking.

Gestionado y ejecutado desde **Terraform Cloud** (HCP Terraform).

---

## Recursos que despliega

| Recurso | Nombre |
|---|---|
| Resource Group | `rg-{cliente}-{colaborador}` |
| Virtual Network | `vnet-{cliente}-{colaborador}` |
| Subnet | `snet-{cliente}-{colaborador}` |
| NSG | `nsg-{cliente}-{colaborador}` |
| Public IP | `pip-{cliente}-{colaborador}` |
| NIC | `nic-{cliente}-{colaborador}` |
| Windows VM (2025 Datacenter) | `vm-{cliente}-{colaborador}` |
| SQL Server | `sql-{cliente}-{colaborador}` |
| SQL Database | `db-{cliente}-{colaborador}` |

---

## Cómo ejecutar

Este proyecto **no se ejecuta localmente**. El plan y apply se gestionan desde:

👉 [app.terraform.io/app/GBM-HA-TEST/workspaces](https://app.terraform.io/app/GBM-HA-TEST/workspaces)

---

## Variables requeridas en Terraform Cloud

Configurar en **Variable Sets** o directamente en el workspace.  
Las marcadas como 🔒 deben ser **Sensitive**.

### Credenciales Azure (Service Principal)

| Variable | Tipo | Sensitive |
|---|---|---|
| `subscription_id` | Terraform | 🔒 |
| `tenant_id` | Terraform | 🔒 |
| `client_id` | Terraform | 🔒 |
| `client_secret` | Terraform | 🔒 |

### Configuración del entorno

| Variable | Tipo | Ejemplo |
|---|---|---|
| `colaborador` | Terraform | `eduardo` |
| `cliente` | Terraform | `democolono` |
| `location` | Terraform | `Central US` |
| `vm_admin_password` | Terraform 🔒 | — |
| `sql_admin_password` | Terraform 🔒 | — |

---

## Estructura del proyecto

```
.
├── main.tf          # Recursos de Azure
├── providers.tf     # Provider AzureRM + backend Terraform Cloud
├── variables.tf     # Declaración de variables
├── outputs.tf       # Outputs del deploy
├── .gitignore       # Excluye credenciales y archivos temporales
└── README.md
```

> ⚠️ El archivo `terraform.tfvars` está excluido del repositorio intencionalmente.  
> Las variables se gestionan directamente en Terraform Cloud.
