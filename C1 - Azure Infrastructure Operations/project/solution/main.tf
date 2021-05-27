provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags = {
    environment = "training"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
//address_space       = ["10.0.2.0/24"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    environment = "training"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

//network security group
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  //explicitly allow access to other VMs on the subnet
  security_rule {
    name                       = "AllowOutboundVirtualNetwork"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  //deny direct access from the internet
  security_rule {
    name                       = "DenyInboundInternet"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "training"
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_network_interface" "main" {
  count = "${var.vmcount}"
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    //public_ip_address_id          = azurerm_public_ip.main.id
  }
  tags = {
    environment = "training"
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-publicip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  tags = {
    environment = "training"
  }
}

//load balancer with public ip on the frontend
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
  tags = {
    environment = "training"
  }
}

//load balancer backend address pool
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "${var.prefix}-lbbap"
}

//load balancer backend address pool association to the network interface
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count = "${var.vmcount}"
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

//virtual machine availability set
resource "azurerm_availability_set" "main" {
  name                        = "${var.prefix}-aset"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tags = {
    environment = "training"
  }
}

//locate the created packer image
data "azurerm_image" "main" {
  name                = "myPackerImage"
  resource_group_name = "udacity-rg"
}

//multiple machines based on variable vmcount
resource "azurerm_linux_virtual_machine" "main" {
  count = "${var.vmcount}"
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  availability_set_id             = azurerm_availability_set.main.id
//size                            = "Standard_D2s_v3"
  size                            = "Standard_B1s"
  admin_username                  = "${var.username}"
  admin_password                  = "${var.password}"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]

  #source_image_reference {
  #  publisher = "Canonical"
  #  offer     = "UbuntuServer"
  #  sku       = "18.04-LTS"
  #  version   = "latest"
  #}

  source_image_id = data.azurerm_image.main.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    environment = "training"
  }
}

//create managed disks for your VMs
resource "azurerm_managed_disk" "main" {
  count = "${var.vmcount}"
  name                 = "${var.prefix}-md-${count.index}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    environment = "training"
  }
}

//attach managed disks to VMs
resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count = "${var.vmcount}"
  managed_disk_id    = azurerm_managed_disk.main[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}