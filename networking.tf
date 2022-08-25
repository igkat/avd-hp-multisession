resource "azurerm_virtual_network" "vnet" {
  name                = "avd-vnet"
  location            = azurerm_resource_group.rg-avd.location
  resource_group_name = azurerm_resource_group.rg-avd.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "defaultSubnet" {
  name                 = "avd-subnet"
  resource_group_name  = azurerm_resource_group.rg-avd.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "avd-nsg"
  location            = azurerm_resource_group.rg-avd.location
  resource_group_name = azurerm_resource_group.rg-avd.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.defaultSubnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface" "sessionhost_nic" {
  count               = 2
  name                = "nic-ansuu-${count.index}"
  location            = azurerm_resource_group.rg-avd.location
  resource_group_name = azurerm_resource_group.rg-avd.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.defaultSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.namew-exa3[*].id, count.index)
  }
}

resource "azurerm_public_ip" "namew-exa3" { //Here defined the public IP
  count               = 2
  name                = "publicIP-${count.index}"
  location            = azurerm_resource_group.rg-avd.location
  resource_group_name = azurerm_resource_group.rg-avd.name
  allocation_method   = "Dynamic"
  #idle_timeout_in_minutes      = 30  
  #domain_name_label            = "hpavdik"  //Here defined the dns name
}