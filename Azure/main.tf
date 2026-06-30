# =============================================================
# MAIN.TF
# El corazón del proyecto. Aquí se declaran todos los recursos.
# =============================================================


# -------------------------------------------------------
# LOCALS
# -------------------------------------------------------

locals {
  nombre_base = lower("${var.cliente}-${var.colaborador}")

  tags = merge(var.tags, {
    cliente     = var.cliente
    colaborador = var.colaborador
  })
}

# -------------------------------------------------------
# RESOURCE GROUP
# -------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.nombre_base}"
  location = var.location
  tags     = local.tags
}

# -------------------------------------------------------
# RED VIRTUAL
# -------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.nombre_base}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "main" {
  name                 = "snet-${local.nombre_base}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -------------------------------------------------------
# NSG - FIREWALL
# ADVERTENCIA: source_address_prefix = "*" permite RDP
# desde cualquier IP pública. Restringe a tu IP o rango
# corporativo en ambientes productivos.
# -------------------------------------------------------

resource "azurerm_network_security_group" "main" {
  name                = "nsg-${local.nombre_base}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# -------------------------------------------------------
# IP PÚBLICA
# -------------------------------------------------------

resource "azurerm_public_ip" "vm" {
  name                = "pip-${local.nombre_base}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# -------------------------------------------------------
# NIC
# -------------------------------------------------------

resource "azurerm_network_interface" "vm" {
  name                = "nic-${local.nombre_base}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

# -------------------------------------------------------
# WINDOWS VM
# -------------------------------------------------------

resource "azurerm_windows_virtual_machine" "main" {
  name                = "vm-${local.nombre_base}"
  computer_name       = substr("vm${var.colaborador}", 0, 15)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  tags                = local.tags

  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  os_disk {
    name                 = "osdisk-${local.nombre_base}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter"
    version   = "latest"
  }
}

# -------------------------------------------------------
# SQL SERVER
# -------------------------------------------------------

resource "azurerm_mssql_server" "main" {
  name                         = "sql-${local.nombre_base}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_user
  administrator_login_password = var.sql_admin_password
  tags                         = local.tags
}

# -------------------------------------------------------
# SQL DATABASE
# -------------------------------------------------------

resource "azurerm_mssql_database" "main" {
  name        = "db-${local.nombre_base}"
  server_id   = azurerm_mssql_server.main.id
  sku_name    = "Basic"
  max_size_gb = 2
  tags        = local.tags
}

# Regla de firewall para que los servicios de Azure se conecten
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "allow-azure-services"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Regla de firewall para que la VM se conecte al SQL
resource "azurerm_mssql_firewall_rule" "allow_vm" {
  name             = "allow-vm"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = azurerm_public_ip.vm.ip_address
  end_ip_address   = azurerm_public_ip.vm.ip_address
}
