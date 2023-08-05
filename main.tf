module "subnet" {
  source           = "ptonini/subnet/azurerm"
  version          = "~> 1.0.0"
  name             = "GatewaySubnet"
  rg               = var.rg
  vnet             = var.vnet
  address_prefixes = var.address_prefixes
}

resource "azurerm_public_ip" "this" {
  name                = "${var.name}-public-ip"
  resource_group_name = var.rg.name
  location            = var.rg.location
  allocation_method   = "Dynamic"
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = var.name
  resource_group_name = var.rg.name
  location            = var.rg.location
  type                = "Vpn"
  sku                 = "VpnGw1"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.this.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.subnet.this.id
  }
  dynamic "custom_route" {
    for_each = var.custom_routes == null ? {} : { dummy = null }
    content {
      address_prefixes = var.custom_routes
    }
  }
  dynamic "vpn_client_configuration" {
    for_each = var.vpn_client == null ? {} : { this = var.vpn_client }
    content {
      address_space        = vpn_client_configuration.value["address_space"]
      vpn_client_protocols = vpn_client_configuration.value["protocols"]
      vpn_auth_types       = vpn_client_configuration.value["auth_types"]
      aad_tenant           = try(vpn_client_configuration.value["aad_tenant"], null)
      aad_issuer           = try(vpn_client_configuration.value["aad_issuer"], null)
      aad_audience         = try(vpn_client_configuration.value["aad_audience"], null)
      dynamic "root_certificate" {
        for_each = try(var.vpn_client["root_certificates"], {})
        content {
          name             = root_certificate.key
          public_cert_data = root_certificate.value
        }
      }
      dynamic "revoked_certificate" {
        for_each = try(var.vpn_client["revoked_certificates"], {})
        content {
          name       = revoked_certificate.key
          thumbprint = revoked_certificate.value
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
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