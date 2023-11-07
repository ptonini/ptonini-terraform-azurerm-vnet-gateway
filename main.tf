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
      tags.business_unit,
      tags.environment,
      tags.product,
      tags.subscription_type
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
      tags.business_unit,
      tags.environment,
      tags.product,
      tags.subscription_type
    ]
  }
}

resource "azurerm_local_network_gateway" "this" {
  for_each            = var.site2site_conns
  name                = "${var.name}-local-gtw-${each.key}"
  resource_group_name = azurerm_virtual_network_gateway.this.resource_group_name
  location            = azurerm_virtual_network_gateway.this.location
  gateway_address     = each.value.gateway_address
  address_space       = each.value.address_space
}

resource "azurerm_virtual_network_gateway_connection" "site2site" {
  for_each                   = var.site2site_conns
  name                       = "${var.name}-site2site-${each.key}"
  resource_group_name        = azurerm_virtual_network_gateway.this.resource_group_name
  location                   = azurerm_virtual_network_gateway.this.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.this[each.key].id
  shared_key                 = each.value.shared_key
  dynamic "ipsec_policy" {
    for_each = each.value.ipsec_policy == null ? {} : { 0 = {} }
    content {
      dh_group         = each.value.ipsec_policy.dh_group
      ike_encryption   = each.value.ipsec_policy.ike_encryption
      ike_integrity    = each.value.ipsec_policy.ike_integrity
      ipsec_encryption = each.value.ipsec_policy.ipsec_encryption
      ipsec_integrity  = each.value.ipsec_policy.ipsec_integrity
      pfs_group        = each.value.ipsec_policy.pfs_group
      sa_lifetime      = each.value.ipsec_policy.sa_lifetime
    }
  }
}

resource "azurerm_virtual_network_gateway_connection" "vnet2vnet" {
  for_each                        = var.vnet2vnet_conns
  name                            = "${var.name}-vnet2vnet-${each.key}"
  resource_group_name             = azurerm_virtual_network_gateway.this.resource_group_name
  location                        = azurerm_virtual_network_gateway.this.location
  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.this.id
  peer_virtual_network_gateway_id = each.value.gateway_id
  shared_key                      = each.value.shared_key
}

