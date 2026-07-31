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
# Tamaño: Standard_B2ats_v2 (2 vCPU, 1 GiB RAM, burstable)
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

  # -------------------------------------------------------
  # DISCO DEL SISTEMA OPERATIVO
  # StandardSSD_LRS: mejor rendimiento que Standard HDD con
  # menor costo que Premium SSD. Adecuado para cargas de trabajo
  # moderadas en entornos de desarrollo/producción ligeros.
  # El cifrado en reposo está habilitado por defecto en Azure
  # (Azure Storage Service Encryption - SSE).
  # -------------------------------------------------------
  os_disk {
    name                 = "osdisk-vm-${local.name_prefix}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = var.os_disk_size_gb

    # Cifrado de disco gestionado por la plataforma Azure (PME)
    # Para cifrado con clave propia, usar disk_encryption_set_id
  }

  # -------------------------------------------------------
  # IMAGEN DEL SISTEMA OPERATIVO
  # Windows Server 2022 Datacenter — última versión estable.
  # Imagen oficial de Microsoft desde Azure Marketplace.
  # -------------------------------------------------------
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  # Deshabilitar la instalación de agentes adicionales
  # que no son necesarios para este deployment básico
  provision_vm_agent = true

  # Habilitar actualizaciones automáticas del SO
  enable_automatic_updates = true

  # Zona horaria del servidor (UTC para ambientes cloud)
  timezone = "UTC"
}

# -------------------------------------------------------
# AZURE SQL SERVER
# Servidor SQL lógico en Azure (PaaS).
# Usa autenticación SQL habilitada con usuario/contraseña.
# La versión "12.0" es la versión estable actual de Azure SQL Server.
# -------------------------------------------------------
resource "azurerm_mssql_server" "main" {
  name                         = "sql-${local.name_prefix}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  tags                         = local.common_tags

  # Mínima versión TLS permitida — se deniegan conexiones con TLS < 1.2
  minimum_tls_version = "1.2"

  # -------------------------------------------------------
  # IDENTIDAD ADMINISTRADA (SYSTEM ASSIGNED)
  # Habilita la identidad administrada del servidor SQL para
  # futuras integraciones con Key Vault u otros servicios Azure.
  # -------------------------------------------------------
  identity {
    type = "SystemAssigned"
  }
}

# -------------------------------------------------------
# AZURE SQL DATABASE
# Base de datos dentro del servidor SQL lógico.
# SKU GP_S_Gen5_1: Serverless General Purpose Gen5 con 1 vCore.
# Serverless escala automáticamente y pausa cuando está inactiva
# (ideal para entornos no-productivos o workloads intermitentes).
# El cifrado Transparent Data Encryption (TDE) está habilitado
# por defecto en todas las bases de datos Azure SQL.
# -------------------------------------------------------
resource "azurerm_mssql_database" "main" {
  name        = "db-${local.name_prefix}"
  server_id   = azurerm_mssql_server.main.id
  sku_name    = var.sql_database_sku
  max_size_gb = var.sql_max_size_gb
  tags        = local.common_tags

  # Habilitar backup geo-redundante (GRS) para DR
  geo_backup_enabled = true

  # Habilitar Transparent Data Encryption explícitamente
  transparent_data_encryption_enabled = true

  # Configuración de Auto-Pause para SKU Serverless (GP_S_*)
  # Se pausa después de 60 minutos de inactividad (mínimo permitido)
  auto_pause_delay_in_minutes = startswith(var.sql_database_sku, "GP_S_") ? 60 : -1
}

# -------------------------------------------------------
# REGLA DE FIREWALL: SERVICIOS DE AZURE
# Permite que los servicios internos de Azure (incluyendo
# Azure Portal, ARM, Azure Monitor, etc.) se conecten al SQL.
# IPs 0.0.0.0 → 0.0.0.0 es la convención de Azure para
# "Allow Azure Services" — no representa acceso público real.
# -------------------------------------------------------
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
