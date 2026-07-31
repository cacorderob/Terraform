# VM Windows + Azure SQL Server — Terraform

Proyecto Terraform para desplegar infraestructura en Azure usando **HCP Terraform** como backend remoto:

- 🖥️ Máquina Virtual Windows Server 2022 (`Standard_B2ats_v2`)
- 🗄️ Azure SQL Server + Base de datos (`GP_S_Gen5_1` Serverless)
- 🌐 Red Virtual, Subred, NSG, IP Pública
- 🔒 DevSecOps integrado: TFLint, Checkov, pre-commit hooks, CI/CD

---

## Recursos que Despliega

| Recurso | Nombre generado |
|---|---|
| Resource Group | `rg-vm-sqlserver-prod` (configurable) |
| Virtual Network | `vnet-carlos-pruebas-production` |
| Subnet | `snet-vm-carlos-pruebas-production` |
| Network Security Group | `nsg-carlos-pruebas-production` |
| Public IP | `pip-vm-carlos-pruebas-production` |
| Network Interface | `nic-vm-carlos-pruebas-production` |
| Windows VM 2022 | `vm-carlos-pruebas-production` |
| Azure SQL Server | `sql-carlos-pruebas-production` |
| Azure SQL Database | `db-carlos-pruebas-production` |

---

## Requisitos Previos

- [Terraform CLI](https://developer.hashicorp.com/terraform/install) >= 1.7.0
- Cuenta en [HCP Terraform](https://app.terraform.io) con organización `GBM-HA-TEST`
- Azure Service Principal con permisos `Contributor` en la suscripción
- [TFLint](https://github.com/terraform-linters/tflint) (opcional, para desarrollo local)
- [Checkov](https://www.checkov.io/) (opcional, para desarrollo local)

---

## Estructura del Proyecto

```
vm-sqlserver-azure/
├── main.tf                     # Recursos Azure: RG, VNet, NSG, VM, SQL
├── variables.tf                # Variables con validaciones y sensitive=true
├── outputs.tf                  # Outputs: rg_id, vm_ip, sql_fqdn, db_name
├── providers.tf                # Backend cloud{} HCP Terraform + provider azurerm
├── versions.tf                 # Versiones fijas de Terraform y providers
├── terraform.tfvars.example    # Ejemplo de variables (sin secretos)
├── .gitignore                  # Exclusión de secretos y archivos temporales
├── .tflint.hcl                 # Configuración TFLint
├── .pre-commit-config.yaml     # Hooks pre-commit: fmt, validate, tflint, checkov
├── README.md                   # Esta documentación
└── tests/
    └── validate_infra_test.go  # Pruebas de validación con Terratest
```

---

## Configuración Inicial

### 1. Clonar el repositorio

```bash
git clone https://github.com/cacorderob/Terraform.git
cd Terraform/vm-sqlserver-azure
```

### 2. Instalar herramientas de desarrollo (opcional, local)

```bash
# Instalar pre-commit y checkov
pip install pre-commit checkov

# Instalar TFLint (Linux/macOS)
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Activar hooks de pre-commit
pre-commit install
```

### 3. Configurar HCP Terraform

Este proyecto **no se ejecuta localmente**. El plan y apply se gestionan desde HCP Terraform.

Ir a: **[app.terraform.io → GBM-HA-TEST → vm-sqlserver-azure](https://app.terraform.io/app/GBM-HA-TEST/workspaces/vm-sqlserver-azure)**

---

## Variables Requeridas en HCP Terraform

### Variables de Entorno (ENV) — todas Sensitive 🔒

> Configurar como **Environment Variables** en el workspace

| Variable | Descripción |
|---|---|
| `ARM_CLIENT_ID` | Client ID del Service Principal de Azure |
| `ARM_CLIENT_SECRET` | Client Secret del Service Principal 🔒 |
| `ARM_SUBSCRIPTION_ID` | ID de la suscripción Azure |
| `ARM_TENANT_ID` | ID del tenant/directorio Azure |

### Variables Terraform

> Configurar como **Terraform Variables** en el workspace

| Variable | Valor por defecto | Sensitive |
|---|---|---|
| `resource_group_name` | `rg-vm-sqlserver-prod` | No |
| `location` | `centralus` | No |
| `environment` | `production` | No |
| `project_name` | `carlos-pruebas` | No |
| `owner` | `cacordero` | No |
| `vm_size` | `Standard_B2ats_v2` | No |
| `sql_database_sku` | `GP_S_Gen5_1` | No |
| `admin_username` | *(requerido)* | Sí 🔒 |
| `admin_password` | *(requerido)* | Sí 🔒 |
| `sql_admin_login` | *(requerido)* | Sí 🔒 |
| `sql_admin_password` | *(requerido)* | Sí 🔒 |

---

## Ejecución del Plan/Apply

> ⚠️ El workspace tiene **auto-apply deshabilitado**. El apply debe ejecutarse manualmente.

1. Ir a [HCP Terraform → vm-sqlserver-azure](https://app.terraform.io/app/GBM-HA-TEST/workspaces/vm-sqlserver-azure)
2. Clic en **"Start new run"** → seleccionar **"Plan and apply"**
3. Revisar el plan detallado
4. Clic en **"Confirm & Apply"** si el plan es correcto

---

## Seguridad

### Reglas NSG configuradas

| Puerto | Protocolo | Dirección | Descripción |
|---|---|---|---|
| 3389 | TCP | Inbound | RDP — acceso remoto a la VM |
| 443 | TCP | Inbound | HTTPS — tráfico web seguro |

> ⚠️ **En producción**: restringir `source_address_prefix` en la regla RDP a la IP corporativa.

### Cifrado

- **Disco OS VM**: Cifrado en reposo mediante Azure Storage Service Encryption (SSE) — habilitado por defecto
- **SQL Database**: Transparent Data Encryption (TDE) habilitado explícitamente
- **Tráfico SQL**: TLS 1.2 mínimo requerido (`minimum_tls_version = "1.2"`)

---

## Outputs Disponibles Post-Apply

| Output | Descripción |
|---|---|
| `resource_group_id` | ID del grupo de recursos |
| `vm_public_ip` | IP pública para conectarse por RDP |
| `vm_rdp_connection` | Cadena de conexión RDP |
| `sql_server_fqdn` | FQDN del SQL Server para cadenas de conexión |
| `sql_database_name` | Nombre de la base de datos |
| `sql_connection_string` | Cadena de conexión ADO.NET (sensitive) |

---

## Desarrollo Local

### Ejecutar validación sin backend

```bash
terraform init -backend=false
terraform validate
terraform fmt -check -recursive
```

### Ejecutar TFLint

```bash
tflint --init
tflint --config=.tflint.hcl
```

### Ejecutar Checkov

```bash
checkov -d . --framework terraform --compact --quiet
```

### Ejecutar tests de Terratest

```bash
cd tests/
go mod init github.com/cacorderob/Terraform/vm-sqlserver-azure/tests
go mod tidy
go test -v -run TestTerraformValidate -timeout 10m
```

---

## Tags Aplicados a Todos los Recursos

```hcl
{
  Environment = "production"
  Project     = "carlos-pruebas"
  ManagedBy   = "Terraform"
  Owner       = "cacordero"
  Workspace   = "vm-sqlserver-azure"
}
```

---

## Costos Estimados (Central US)

| Recurso | SKU | Costo estimado/mes |
|---|---|---|
| VM Windows | Standard_B2ats_v2 | ~$15–25 USD |
| SQL Database | GP_S_Gen5_1 Serverless | ~$0–30 USD (según uso) |
| Public IP | Standard Static | ~$4 USD |
| Disco OS 128GB | StandardSSD_LRS | ~$10 USD |
| **Total aproximado** | | **~$30–70 USD/mes** |

> 💡 El SKU `GP_S_Gen5_1` Serverless pausa la DB después de 60 min de inactividad, reduciendo costos.

---

## Contribución

1. Crear una rama: `git checkout -b feat/mi-cambio`
2. Los pre-commit hooks validarán automáticamente el código
3. Hacer PR hacia `main`
4. El pipeline CI ejecutará: `fmt-check → validate → tflint → checkov → plan`

---

> Gestionado con [HCP Terraform](https://app.terraform.io) | Organización: `GBM-HA-TEST` | Proyecto: `Carlos pruebas`
