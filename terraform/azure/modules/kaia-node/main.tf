resource "azurerm_linux_virtual_machine" "this" {
  name                = var.name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  size                = var.instance_size
  admin_username      = "kaia"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  plan {
    name      = var.source_image_reference.sku
    product   = var.source_image_reference.offer
    publisher = var.source_image_reference.publisher
  }

  admin_ssh_key {
    username   = "kaia"
    public_key = var.public_key
  }

  os_disk {
    name                 = format("%s-os-disk", var.name)
    caching              = lookup(var.os_disk, "caching", "ReadWrite")
    storage_account_type = lookup(var.os_disk, "storage_account_type", "Premium_LRS")
    disk_size_gb         = lookup(var.os_disk, "disk_size_gb", 8)
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "azurerm_network_interface" "this" {
  name                = format("%s-nic", var.name)
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  ip_configuration {
    name                          = format("%s-private-ip", var.name)
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_network_interface_security_group_association" "layer1" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.security_group_id
}

resource "azurerm_public_ip" "this" {
  name                = format("%s-public-ip", var.name)
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, { Name = var.name })
}

resource "azurerm_managed_disk" "this" {
  for_each = { for v in var.data_disk : v.name => v }

  name                 = format("%s-data-disk", var.name)
  resource_group_name  = data.azurerm_resource_group.this.name
  location             = data.azurerm_resource_group.this.location
  storage_account_type = lookup(each.value, "storage_account_type", "Premium_LRS")
  create_option        = "Empty"
  disk_size_gb         = lookup(each.value, "disk_size_gb", 100)

  tags = merge(var.tags, { Name = var.name })
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = { for v in var.data_disk : v.name => v }
  # count = var.data_disk != null ? 1 : 0

  managed_disk_id    = azurerm_managed_disk.this[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = "10"
  caching            = "ReadWrite"
}
