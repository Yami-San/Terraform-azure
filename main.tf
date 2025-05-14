resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# ──────────────── Compute: B1S VM ────────────────
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
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
      "sudo chown ${var.admin_username}:${var.admin_username} /opt/scripts"
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


# ──────────────── Storage: General Purpose v2 ────────────────
resource "azurerm_storage_account" "sa" {
  name                     = lower(substr("${var.prefix}sa", 0, 24))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"               # up to 5 GB free :contentReference[oaicite:4]{index=4}
}

# ──────────────── Monitoring: Log Analytics ────────────────
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku                 = "PerGB2018"             # ingestion charged beyond free 5 GB/month :contentReference[oaicite:5]{index=5}
  retention_in_days   = 31                      # free retention :contentReference[oaicite:6]{index=6}
}

resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  name                       = "vm-diag"
  target_resource_id         = azurerm_linux_virtual_machine.vm.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = false
      days    = 0
    }
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "allow-ssh"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
