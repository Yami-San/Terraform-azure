resource "azurerm_resource_group" "rg" {
  name     = "freedemostore"
  location = var.location
}

# ──────────────── Compute: B1S VM ────────────────
resource "azurerm_virtual_network" "vnet" {
  name                = "freedemo-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "mi-vm-ubuntu"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1ms"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false

  custom_data = base64encode(file("${path.module}/scripts/cloud_init.sh"))

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    name                 = "mi-vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/scripts",
      "sudo chown ${var.admin_username}:${var.admin_username} /opt/scripts",
      # Instala sqlcmd
      "curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -",
      "sudo add-apt-repository \"$(curl https://packages.microsoft.com/config/ubuntu/24.04/prod.list)\"",
      "sudo apt-get update",
      "sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev",
      "echo 'export PATH=\"$PATH:/opt/mssql-tools/bin\"' >> /etc/profile.d/sqlcmd.sh",
      "source /etc/profile.d/sqlcmd.sh",

      # Ejecuta los scripts ya subidos
      "sqlcmd -S ${azurerm_mssql_server.sqlsrv.fully_qualified_domain_name} -d mySqlDb -U sqladminuser -P '${var.admin_password}' -i /opt/scripts/create_tables.sql",
      "sqlcmd -S ${azurerm_mssql_server.sqlsrv.fully_qualified_domain_name} -d mySqlDb -U sqladminuser -P '${var.admin_password}' -i /opt/scripts/seed_and_query.sql"
    ]
    connection {
      type        = "ssh"
      host        = self.public_ip_address
      user        = var.admin_username
      password    = var.admin_password
      timeout     = "2m"
    }
  }

  provisioner "file" {
  source      = "${path.module}/scripts/init_vm.sh"
  destination = "/opt/scripts/init_vm.sh"

  connection {
    type     = "ssh"
    user     = var.admin_username
    password = var.admin_password
    host     = self.public_ip_address
  }
}

  provisioner "file" {
    source      = "${path.module}/scripts/create_tables.sql"
    destination = "/opt/scripts/create_tables.sql"

    connection {
      host     = self.public_ip_address
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
    }
  }

  provisioner "file" {
    source      = "${path.module}/scripts/seed_and_query.sql"
    destination = "/opt/scripts/seed_and_query.sql"

    connection {
      host     = self.public_ip_address
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
    }
  }

  provisioner "file" {
    source      = "${path.module}/scripts/drop_database.sql"
    destination = "/opt/scripts/drop_database.sql"

    connection {
      host     = self.public_ip_address
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
    }
  }

  provisioner "file" {
    source      = "${path.module}/scripts/destroy_infra.sh"
    destination = "/opt/scripts/destroy_infra.sh"

    connection {
      host     = self.public_ip_address
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
    }
  }
}

# --------------- Azure Blob Storage --------------

# Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}store"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

# Storage Container
resource "azurerm_storage_container" "jeandata" {
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
  depends_on            = [azurerm_storage_account.example]
}

# Storage Blob
resource "azurerm_storage_blob" "jeandata" {
  name                   = "archivo-de-jean.txt"
  storage_account_name   = azurerm_storage_account.example.name
  storage_container_name = azurerm_storage_container.jeandata.name
  type                   = "Block"
  source                 = "${path.module}/scripts/jean.txt"
  
  # Opcional pero recomendable: forzar recarga si cambia el contenido
  content_md5            = filemd5("${path.module}/scripts/jean.txt")
  # Opcional: especificar el tipo MIME correcto
  content_type           = "text/plain"
}

# ───────────── Azure SQL Database ─────────────

#SQL Server
resource "azurerm_mssql_server" "sqlsrv" {
  name                         = "sqlserverdejeanmarcop"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = var.admin_password
}

#SQL Database
resource "azurerm_mssql_database" "sqldb" {
  name                = "mySqlDb"
  server_id = azurerm_mssql_server.sqlsrv.id
  sku_name            = "S0"
  max_size_gb = 2
}

# Auxiliar: sufijo único
resource "random_id" "suffix" {
  byte_length = 4
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}