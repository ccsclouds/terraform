# Define your Azure provider and authentication details
provider "azurerm" {
  features {}
}

# Define the resource group where the VMs will be created
resource "azurerm_resource_group" "rg" {
  name     = "my-rg"
  location = "East US"
}

# Define the virtual network where the VMs will be deployed
resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Define the subnet where the VMs will be deployed
resource "azurerm_subnet" "subnet" {
  name                 = "my-subnet"
  address_prefixes     = ["10.0.1.0/24"]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# Define the public IP addresses for the VMs
resource "azurerm_public_ip" "public_ips" {
  count               = 2
  name                = "my-public-ip-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Define the network interface cards for the VMs
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "my-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ips[count.index].id
  }
}

# Define the virtual machines
resource "azurerm_virtual_machine" "vm" {
  count               = 2
  name                = "my-vm-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]
  vm_size             = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "my-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "my-vm-${count.index}"
    admin_username = "myadmin"
    admin_password = "P@ssword!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
