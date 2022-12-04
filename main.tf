module "subnet" {
  source           = "ptonini/subnet/azurerm"
  version          = "~> 1.0.0"
  name             = "GatewaySubnet"
  rg               = var.rg
  vnet             = var.vnet
  address_prefixes = var.address_prefixes
}

resource "azurerm_public_ip" "this" {
  name                = "${var.name}_virtual-network-gateway"
  resource_group_name = var.rg.name
  location            = var.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = var.name
  resource_group_name = var.rg.name
  location            = var.rg.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw1"
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.this.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.subnet.this.id
  }
}

resource "azurerm_virtual_network_gateway_connection" "vnet2vnet" {
  for_each                        = var.vnet2vnet_conns
  name                            = each.key
  type                            = "Vnet2Vnet"
  resource_group_name             = var.rg.name
  location                        = var.rg.location
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.this.id
  peer_virtual_network_gateway_id = each.value.gateway_id
  shared_key                      = each.value.shared_key
}