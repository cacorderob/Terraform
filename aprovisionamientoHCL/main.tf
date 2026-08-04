# ============================================================
# main.tf
# Recurso principal: define toda la infraestructura de Azure
# incluyendo el grupo de recursos, red, VM Windows y
# Azure SQL Server + Database.
# ============================================================

# ─── Grupo de recursos ──────────────────────────────────────
# Contenedor lógico de todos los recursos del proyecto.

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

# ─── Red virtual ────────────────────────────────────────────
# Red privada dedicada para aislar los recursos de la VM.

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# ─── Subred para la VM ──────────────────────────────────────
# Segmento de red exclusivo donde residirá la máquina virtual.

resource "azurerm_subnet" "vm" {
  name                 = "snet-vm-${var.project_name}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefix]
}

# ─── IP Pública ─────────────────────────────────────────────
# Dirección IP pública estática asignada a la NIC de la VM.
# Se usa para acceso remoto (RDP) controlado por NSG.

resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# ─── Network Security Group ─────────────────────────────────
# Firewall a nivel de NIC: solo permite RDP (3389) y HTTPS (443).
# El tráfico de salida queda restringido a HTTPS por seguridad.

resource "azurerm_network_security_group" "vm" {
  name                = "nsg-vm-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Permite RDP desde cualquier IP de origen (restringir en producción real)
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Permite HTTPS entrante
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
  }

  # Deniega todo el tráfico de entrada no listado explícitamente
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# ─── Asociación NSG ↔ Subred ────────────────────────────────
# Aplica las reglas del NSG a toda la subred de la VM.

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# ─── Interfaz de red ────────────────────────────────────────
# NIC que conecta la VM a la subred y asigna la IP pública.

resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = local.common_tags
}

# ─── Máquina Virtual Windows ────────────────────────────────
# VM Windows Server 2022 Datacenter con disco OS cifrado.
# Credenciales gestionadas vía variables sensibles en HCP Terraform.

resource "azurerm_windows_virtual_machine" "main" {
  name                = "vm-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size

  # computer_name debe tener máximo 15 caracteres (límite de Windows).
  # Se usa un nombre corto derivado del sufijo aleatorio del SQL Server.
  computer_name = "vm-${random_id.sql_suffix.hex}"

  # Credenciales sensibles: jamás se almacenan en texto plano en el código
  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  # Disco del sistema operativo con cifrado gestionado por la plataforma
  os_disk {
    name                 = "osdisk-vm-${var.project_name}-${var.environment}"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type

    # Cifrado del disco OS: usa la clave gestionada por la plataforma (PME)
    # Para mayor seguridad se puede configurar CMK (Customer-Managed Keys)
  }

  # Imagen: Windows Server 2022 Datacenter — última versión estable
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  # Habilita la extensión de Azure Monitoring y actualizaciones automáticas
  enable_automatic_updates = true
  patch_mode               = "AutomaticByOS"

  # Arranque seguro y vTPM para mayor seguridad (Trusted Launch)
  secure_boot_enabled = true
  vtpm_enabled        = true

  tags = local.common_tags
}

# ─── Azure SQL Server ────────────────────────────────────────
# Servidor lógico de SQL con autenticación SQL habilitada.
# El nombre debe ser único globalmente en Azure.

resource "azurerm_mssql_server" "main" {
  name                         = "sql-${var.project_name}-${var.environment}-${random_id.sql_suffix.hex}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = var.sql_server_version
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

  # Habilita la autenticación de Azure AD como método adicional (buena práctica)
  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }

  # Cifrado de la conexión TLS mínima versión 1.2
  minimum_tls_version = "1.2"

  tags = local.common_tags
}

# ─── Sufijo aleatorio para el nombre único del SQL Server ────
resource "random_id" "sql_suffix" {
  byte_length = 4
}

# ─── Azure SQL Database ──────────────────────────────────────
# Base de datos dentro del servidor SQL lógico.
# SKU configurable, por defecto GP_S_Gen5_1 (serverless Gen5).

resource "azurerm_mssql_database" "main" {
  name      = "sqldb-${var.project_name}-${var.environment}"
  server_id = azurerm_mssql_server.main.id
  sku_name  = var.sql_database_sku

  # Capacidad mínima requerida por el SKU serverless GP_S_Gen5_*.
  # Azure exige min_capacity > 0 (mínimo 0.5 vCores) cuando auto-pause está habilitado.
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60

  # Cifrado de datos en reposo habilitado (TDE - Transparent Data Encryption)
  transparent_data_encryption_enabled = true

  tags = local.common_tags
}

# ─── Regla de firewall SQL: Servicios de Azure ───────────────
# Permite que los servicios internos de Azure se conecten al servidor SQL.
# IPs 0.0.0.0/0.0.0.0 es el rango especial de Azure para servicios internos.

resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ─── Data sources ───────────────────────────────────────────
# Obtiene la configuración del cliente actual (usado para Azure AD admin en SQL)

data "azurerm_client_config" "current" {}

# ─── Locals: etiquetas comunes ──────────────────────────────
# Etiquetas estándar aplicadas a todos los recursos para
# facilitar la gestión de costos, auditoría y cumplimiento.

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}
