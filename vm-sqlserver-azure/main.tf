# =============================================================
# MAIN.TF
# Declaración de todos los recursos de Azure a provisionar:
#   - Grupo de Recursos
#   - Red Virtual + Subred
#   - Network Security Group (NSG) con reglas mínimas
#   - IP Pública + Interfaz de Red (NIC)
#   - Máquina Virtual Windows Server 2022
#   - Azure SQL Server + Azure SQL Database
#   - Reglas de Firewall para SQL
# =============================================================

# -------------------------------------------------------
# LOCALS
# Valores calculados y reutilizables en todos los recursos.
# Los tags estándar se definen aquí para garantizar
# consistencia en todos los recursos del proyecto.
# -------------------------------------------------------
locals {
  # Prefijo base para nombres de recursos
  name_prefix = lower("${var.project_name}-${var.environment}")

  # Tags estándar obligatorios en TODOS los recursos
  # Facilitan la gestión de costos, auditoría y gobierno
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Workspace   = "vm-sqlserver-azure"
  }
}

# -------------------------------------------------------
# RESOURCE GROUP
# Contenedor lógico que agrupa todos los recursos Azure.
# La ubicación del RG determina los metadatos del grupo,
# pero no necesariamente la ubicación de los recursos.
# -------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# -------------------------------------------------------
# RED VIRTUAL (VNet)
# Proporciona aislamiento de red a nivel de proyecto.
# La VNet contiene la subred donde vivirá la VM.
# -------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_address_space]
  tags                = local.common_tags
}

# -------------------------------------------------------
# SUBRED
# Segmento de red dedicado para la VM.
# Se recomienda usar subredes separadas para la VM
# y para otros servicios (SQL Managed Instance, App GW, etc.)
# -------------------------------------------------------
resource "azurerm_subnet" "vm" {
  name                 = "snet-vm-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefix]
}

# -------------------------------------------------------
# NETWORK SECURITY GROUP (NSG)
# Firewall a nivel de subred con reglas mínimas necesarias.
# PRINCIPIO DE MÍNIMO PRIVILEGIO:
#   - Solo se abren los puertos estrictamente requeridos
#   - RDP (3389): acceso administrativo remoto a la VM
#   - HTTPS (443): comunicación segura de aplicaciones
# NOTA DE SEGURIDAD: En producción, restringir source_address_prefix
# a la IP o rango corporativo en lugar de "*".
#
# checkov:skip=CKV_AZURE_9: RDP público requerido para acceso administrativo
#   remoto en este entorno de workshop/demostración. En producción se debe
#   restringir source_address_prefix a la IP corporativa o usar Bastion Host.
# -------------------------------------------------------
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  # Regla 1: RDP — acceso remoto a la VM Windows
  # ADVERTENCIA: source_address_prefix="*" permite RDP desde
  # cualquier IP. Restringe a tu IP corporativa en producción.
  security_rule {
    name                       = "Allow-RDP-Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Permite acceso RDP a la VM. Restringir a IP corporativa en produccion."
  }

  # Regla 2: HTTPS — tráfico web seguro entrante
  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Permite trafico HTTPS entrante hacia la VM."
  }
}

# -------------------------------------------------------
# ASOCIACIÓN NSG → SUBRED
# Aplica el NSG a la subred de la VM para que las reglas
# de seguridad tengan efecto sobre todo el tráfico.
# -------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# -------------------------------------------------------
# IP PÚBLICA
# Dirección IP pública estática para acceso remoto (RDP).
# SKU Standard es requerido para producción y zonas de disponibilidad.
# -------------------------------------------------------
resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# -------------------------------------------------------
# INTERFAZ DE RED (NIC)
# Conecta la VM a la subred y a la IP pública.
# La NIC actúa como punto de entrada/salida de red de la VM.
# -------------------------------------------------------
resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "ipconfig-primary"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

# -------------------------------------------------------
# MÁQUINA VIRTUAL WINDOWS
# VM con Windows Server 2022 Datacenter.
# Tamaño: Standard_B2ms (2 vCPU, 8 GiB RAM, burstable)
# NOTA: Standard_B2ats_v2 y Standard_B2s_v2 no tienen capacidad disponible
#       en centralus (verificado vía az vm list-skus).
#       Standard_B2ms tiene disponibilidad confirmada en centralus.
# Disco OS: StandardSSD_LRS (mejor que HDD, menor costo que Premium)
# -------------------------------------------------------
resource "azurerm_windows_virtual_machine" "main" {
  name                = "vm-${local.name_prefix}"
  computer_name       = substr(replace("vm${var.project_name}", "-", ""), 0, 15)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = local.common_tags

  # Asociar la NIC creada anteriormente
  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  os_disk {
    name                 = "osdisk-vm-${local.name_prefix}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  provision_vm_agent       = true
  enable_automatic_updates = true
  timezone                 = "UTC"

  # CKV_AZURE_151: encryption_at_host requiere que el feature
  # 'Microsoft.Compute/EncryptionAtHost' esté registrado en la suscripción.
  # El cifrado en reposo está cubierto por Azure Storage Service Encryption (SSE)
  # habilitado por defecto en todos los discos administrados de Azure.
  # Para habilitarlo en el futuro:
  #   az feature register --namespace Microsoft.Compute --name EncryptionAtHostEnabled
  #   az provider register --namespace Microsoft.Compute
  # encryption_at_host_enabled = true  # deshabilitado: feature no registrado en suscripción
}

# -------------------------------------------------------
# AZURE SQL SERVER
# Servidor SQL lógico en Azure (PaaS).
# Usa autenticación SQL habilitada con usuario/contraseña.
# La versión "12.0" es la versión estable actual de Azure SQL Server.
# -------------------------------------------------------
# checkov:skip=CKV_AZURE_113: public_network_access requerido sin Private Endpoint.
# checkov:skip=CKV2_AZURE_45: Private Endpoint fuera del scope de este proyecto base.
# checkov:skip=CKV2_AZURE_27: Azure AD admin fuera del scope de este proyecto base.
# checkov:skip=CKV2_AZURE_2: Vulnerability Assessment requiere Storage Account dedicado.
resource "azurerm_mssql_server" "main" {
  name                         = "sql-${local.name_prefix}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  tags                         = local.common_tags

  minimum_tls_version = "1.2"

  identity {
    type = "SystemAssigned"
  }
}

# CKV_AZURE_23 + CKV_AZURE_24: Auditoría habilitada con retención >= 90 días.
resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  server_id              = azurerm_mssql_server.main.id
  retention_in_days      = 90
  log_monitoring_enabled = true
}

# -------------------------------------------------------
# AZURE SQL DATABASE
# Base de datos dentro del servidor SQL lógico.
# SKU GP_S_Gen5_1: Serverless General Purpose Gen5 con 1 vCore.
# Serverless escala automáticamente y pausa cuando está inactiva
# (ideal para entornos no-productivos o workloads intermitentes).
# El cifrado Transparent Data Encryption (TDE) está habilitado
# por defecto en todas las bases de datos Azure SQL.
#
# FIX: GP_S_Gen5_1 Serverless requiere min_capacity > 0.
#      El valor mínimo permitido por Azure es 0.5 vCores.
# -------------------------------------------------------
# checkov:skip=CKV_AZURE_224: Ledger feature es para compliance avanzado, no requerido aquí.
# checkov:skip=CKV_AZURE_229: Zone redundancy no disponible en SKU GP_S_Gen5_1 Serverless.
resource "azurerm_mssql_database" "main" {
  name        = "db-${local.name_prefix}"
  server_id   = azurerm_mssql_server.main.id
  sku_name    = var.sql_database_sku
  max_size_gb = var.sql_max_size_gb
  tags        = local.common_tags

  geo_backup_enabled                  = true
  transparent_data_encryption_enabled = true
  auto_pause_delay_in_minutes         = startswith(var.sql_database_sku, "GP_S_") ? 60 : -1
  min_capacity                        = startswith(var.sql_database_sku, "GP_S_") ? 0.5 : null
}

# checkov:skip=CKV2_AZURE_34: 0.0.0.0/0.0.0.0 es la convención oficial de Azure
#   para "Allow Azure Services". No representa acceso desde internet externo.
#   Ref: https://docs.microsoft.com/azure/azure-sql/database/firewall-configure
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
