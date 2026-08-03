# Terraform Azure — VM Windows + SQL Server

[![Terraform CI](https://github.com/cacorderob/Terraform/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/cacorderob/Terraform/actions/workflows/terraform-ci.yml)
[![Checkov](https://img.shields.io/badge/security-checkov-green)](https://www.checkov.io/)
[![TFLint](https://img.shields.io/badge/linter-tflint-blue)](https://github.com/terraform-linters/tflint)

## Descripción

Proyecto Terraform para aprovisionar infraestructura en **Azure Central US** que incluye:

- ✅ Máquina virtual Windows Server 2022 Datacenter (Standard_B2ats_v2)
- ✅ Azure SQL Server + SQL Database (serverless GP_S_Gen5_1)
- ✅ Red virtual con subred dedicada
- ✅ Network Security Group (RDP 3389 + HTTPS 443)
- ✅ IP Pública estática
- ✅ Gestión de estado remoto en **HCP Terraform**
- ✅ Pipeline CI/CD con GitHub Actions (SAST, escaneo de secretos, SCA)

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│  Resource Group: rg-vm-sqlserver-prod  (Central US)         │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Virtual Network: vnet-carlos-pruebas-production      │  │
│  │  Address Space: 10.0.0.0/16                           │  │
│  │                                                       │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  Subnet: snet-vm-carlos-pruebas 10.0.1.0/24    │  │  │
│  │  │                    │                            │  │  │
│  │  │  ┌─────────────────▼──────────────────────┐    │  │  │
│  │  │  │  NSG: nsg-vm (RDP:3389, HTTPS:443)     │    │  │  │
│  │  │  └────────────────────────────────────────┘    │  │  │
│  │  │                    │                            │  │  │
│  │  │  ┌─────────────────▼──────────────────────┐    │  │  │
│  │  │  │  NIC → Public IP (Static)               │    │  │  │
│  │  │  │  ┌────────────────────────────────┐     │    │  │  │
│  │  │  │  │  VM Windows Server 2022        │     │    │  │  │
│  │  │  │  │  Standard_B2ats_v2             │     │    │  │  │
│  │  │  │  │  OS Disk: StandardSSD_LRS      │     │    │  │  │
│  │  │  │  │  Secure Boot + vTPM            │     │    │  │  │
│  │  │  │  └────────────────────────────────┘     │    │  │  │
│  │  │  └────────────────────────────────────────┘    │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Azure SQL Server (TLS 1.2+, Azure AD Admin)         │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │  SQL Database: GP_S_Gen5_1 serverless        │    │   │
│  │  │  TDE: habilitado (cifrado en reposo)          │    │   │
│  │  └─────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerrequisitos

| Herramienta | Versión mínima | Propósito |
|-------------|---------------|-----------|
| [Terraform](https://www.terraform.io/downloads) | >= 1.6.0 | IaC principal |
| [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) | >= 2.50 | Autenticación local |
| [TFLint](https://github.com/terraform-linters/tflint) | >= 0.50 | Análisis estático |
| [Checkov](https://www.checkov.io/) | >= 3.0 | Seguridad SAST |
| [pre-commit](https://pre-commit.com/) | >= 3.0 | Hooks de calidad |
| Cuenta [HCP Terraform](https://app.terraform.io) | — | Estado remoto |
| Cuenta Azure + Service Principal | — | Cloud provider |

---

## Estructura del proyecto

```
aprovisionamientoHCL/
├── main.tf                      # Recursos principales de Azure
├── variables.tf                 # Variables de entrada con validaciones
├── outputs.tf                   # Salidas exportadas
├── providers.tf                 # Proveedor AzureRM + backend HCP Terraform
├── versions.tf                  # Versiones de Terraform y proveedores
├── terraform.tfvars.example     # Plantilla de variables (sin secretos)
├── .gitignore                   # Exclusiones de archivos sensibles
├── .tflint.hcl                  # Configuración de TFLint
├── .pre-commit-config.yaml      # Hooks de pre-commit
├── README.md                    # Esta documentación
├── .github/
│   └── workflows/
│       └── terraform-ci.yml     # Pipeline CI/CD (GitHub Actions)
└── tests/
    ├── validate_infra_test.go   # Pruebas Terratest
    └── go.mod                   # Módulo Go para pruebas
```

---

## Configuración inicial

### 1. Clonar el repositorio

```bash
git clone https://github.com/cacorderob/Terraform.git
cd Terraform
```

### 2. Configurar pre-commit (opcional, recomendado)

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

### 3. Crear un Service Principal en Azure

```bash
# Autenticarse en Azure
az login

# Crear Service Principal con rol Contributor
az ad sp create-for-rbac \
  --name "sp-terraform-vm-sqlserver" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID> \
  --output json
```

Guarda los valores devueltos: `appId`, `password`, `tenant`.

### 4. Configurar variables en HCP Terraform

En el workspace `vm-sqlserver-azure` de HCP Terraform, completa las siguientes variables sensibles:

| Variable | Categoría | Valor |
|----------|-----------|-------|
| `ARM_CLIENT_ID` | env | `appId` del Service Principal |
| `ARM_CLIENT_SECRET` | env | `password` del Service Principal |
| `ARM_SUBSCRIPTION_ID` | env | ID de tu suscripción Azure |
| `ARM_TENANT_ID` | env | `tenant` del Service Principal |
| `admin_username` | terraform | Usuario administrador de la VM |
| `admin_password` | terraform | Contraseña de la VM (mín. 12 chars) |
| `sql_admin_login` | terraform | Login del SQL Server |
| `sql_admin_password` | terraform | Contraseña SQL (mín. 16 chars) |

### 5. Ejecutar Terraform

```bash
# Inicializar (conecta con HCP Terraform como backend)
terraform init

# Verificar el plan
terraform plan

# Aplicar (o hacerlo desde HCP Terraform — recomendado)
# El apply debe ejecutarse MANUALMENTE desde la UI de HCP Terraform
```

---

## Variables de entrada

| Nombre | Tipo | Requerido | Por defecto | Descripción |
|--------|------|-----------|-------------|-------------|
| `resource_group_name` | string | ✅ | — | Nombre del grupo de recursos |
| `location` | string | | `centralus` | Región de Azure |
| `environment` | string | | `production` | Entorno (production/staging/development) |
| `project_name` | string | | `carlos-pruebas` | Nombre del proyecto para etiquetas |
| `owner` | string | | `cacorderob` | Responsable de los recursos |
| `vnet_address_space` | list(string) | | `["10.0.0.0/16"]` | CIDR de la red virtual |
| `subnet_address_prefix` | string | | `10.0.1.0/24` | CIDR de la subred de la VM |
| `vm_size` | string | | `Standard_B2ats_v2` | Tamaño de la VM |
| `admin_username` | string | ✅ 🔒 | — | Usuario admin de la VM |
| `admin_password` | string | ✅ 🔒 | — | Contraseña admin de la VM |
| `os_disk_type` | string | | `StandardSSD_LRS` | Tipo de disco OS |
| `sql_admin_login` | string | ✅ 🔒 | — | Login del SQL Server |
| `sql_admin_password` | string | ✅ 🔒 | — | Contraseña del SQL Server |
| `sql_database_sku` | string | | `GP_S_Gen5_1` | SKU de la SQL Database |
| `sql_server_version` | string | | `12.0` | Versión del SQL Server |

🔒 = Variable sensible (sensitive = true)

---

## Outputs

| Nombre | Descripción |
|--------|-------------|
| `resource_group_id` | ID del grupo de recursos |
| `resource_group_name` | Nombre del grupo de recursos |
| `vm_public_ip_address` | IP pública de la VM (para RDP) |
| `vm_private_ip_address` | IP privada de la VM |
| `vm_id` | ID del recurso de la VM |
| `vm_name` | Nombre de la VM |
| `sql_server_fqdn` | FQDN del SQL Server para conexiones |
| `sql_server_name` | Nombre del SQL Server |
| `sql_database_name` | Nombre de la base de datos |
| `sql_database_id` | ID de la base de datos |
| `virtual_network_id` | ID de la red virtual |
| `subnet_id` | ID de la subred de la VM |
| `nsg_id` | ID del Network Security Group |

---

## Pipeline CI/CD

El pipeline `.github/workflows/terraform-ci.yml` ejecuta automáticamente:

```
Push/PR → fmt-check → validate → tflint → checkov (SAST) → secret-scan → trivy (SCA) → plan
```

| Paso | Herramienta | Propósito |
|------|------------|-----------|
| Formato | `terraform fmt -check` | Estilo de código |
| Validación | `terraform validate` | Sintaxis y configuración |
| Análisis estático | TFLint | Errores de tipo y buenas prácticas |
| Seguridad SAST | Checkov | Detecta misconfiguraciones de seguridad |
| Secretos | TruffleHog | Detecta secretos en el historial de Git |
| Dependencias SCA | Trivy | Vulnerabilidades en dependencias |
| Plan | `terraform plan` | Previsualización de cambios |

> ⚠️ **El `apply` NUNCA se ejecuta automáticamente.** Siempre debe realizarse manualmente desde HCP Terraform.

---

## Seguridad

- ✅ Todas las credenciales gestionadas como variables sensibles en HCP Terraform
- ✅ TLS 1.2+ forzado en el SQL Server
- ✅ Transparent Data Encryption (TDE) habilitado en la base de datos
- ✅ Secure Boot + vTPM habilitados en la VM
- ✅ Network Security Group con reglas de mínimo privilegio
- ✅ Archivos `.tfstate` y `.tfvars` excluidos del repositorio via `.gitignore`
- ✅ Escaneo automático de secretos con TruffleHog en cada push

---

## Etiquetas estándar de recursos

Todos los recursos incluyen las siguientes etiquetas:

```hcl
tags = {
  Environment = "production"
  Project     = "carlos-pruebas"
  ManagedBy   = "Terraform"
  Owner       = "cacorderob"
  CreatedDate = "YYYY-MM-DD"
}
```

---

## Workspace HCP Terraform

- **Organización**: cacorderob
- **Proyecto**: Carlos pruebas
- **Workspace**: vm-sqlserver-azure
- **URL**: https://app.terraform.io/app/cacorderob/workspaces/vm-sqlserver-azure
- **Execution mode**: Remote
- **Auto-apply**: Deshabilitado (apply manual)

---

## Pruebas

```bash
cd tests
go mod tidy
go test -v -timeout 30m -run TestTerraformValidate
```

---

## Licencia

MIT License — Ver [LICENSE](LICENSE) para más detalles.

---

*Gestionado con [HCP Terraform](https://app.terraform.io) | Infraestructura como Código con [Terraform](https://www.terraform.io)*
