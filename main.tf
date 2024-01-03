module "subnet" {
  source           = "ptonini/subnet/azurerm"
  version          = "~> 1.0.0"
  count            = var.subnet == null ? 0 : 1
  name             = "GatewaySubnet"
  rg               = var.rg
  vnet             = var.subnet.vnet
  address_prefixes = var.subnet.address_prefixes
}

resource "azurerm_public_ip" "this" {
  name                = "${var.name}-public-ip"
  resource_group_name = var.rg.name
  location            = var.rg.location
  allocation_method   = "Dynamic"

  lifecycle {
    ignore_changes = [
      tags["business_unit"],
      tags["environment_finops"],
      tags["environment"],
      tags["product"],
      tags["subscription_type"]
    ]
  }
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = var.name
  resource_group_name = var.rg.name
  location            = var.rg.location
  type                = var.type
  sku                 = var.sku
  vpn_type            = var.vpn_type
  active_active       = false
  enable_bgp          = false

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.this.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = coalesce(var.subnet_id, module.subnet[0].this.id)
  }

  custom_route {
    address_prefixes = var.custom_routes
  }

  dynamic "vpn_client_configuration" {
    for_each = var.vpn_client_configuration[*]
    content {
      address_space        = vpn_client_configuration.value.address_space
      vpn_client_protocols = vpn_client_configuration.value.protocols
      vpn_auth_types       = vpn_client_configuration.value.auth_types
      aad_tenant           = vpn_client_configuration.value.aad_tenant
      aad_issuer           = vpn_client_configuration.value.aad_issuer
      aad_audience         = vpn_client_configuration.value.aad_audience

      dynamic "root_certificate" {
        for_each = vpn_client_configuration.value.root_certificates
        content {
          name             = root_certificate.key
          public_cert_data = root_certificate.value
        }
      }

      dynamic "revoked_certificate" {
        for_each = vpn_client_configuration.value.revoked_certificates
        content {
          name       = revoked_certificate.key
          thumbprint = revoked_certificate.value
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      tags["business_unit"],
      tags["environment_finops"],
      tags["environment"],
      tags["product"],
      tags["subscription_type"]
    ]
  }
}

resource "azurerm_local_network_gateway" "this" {
  for_each            = { for k, v in var.connections : k => v if v.type == "IPsec" }
  name                = "${var.name}-local-gtw-${each.key}"
  resource_group_name = azurerm_virtual_network_gateway.this.resource_group_name
  location            = azurerm_virtual_network_gateway.this.location
  gateway_address     = each.value.gateway_address
  address_space       = each.value.address_space
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each                        = var.connections
  name                            = "${var.name}-${each.key}"
  resource_group_name             = azurerm_virtual_network_gateway.this.resource_group_name
  location                        = azurerm_virtual_network_gateway.this.location
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.this.id
  type                            = each.value.type
  local_network_gateway_id        = each.value.type == "IPsec" ? azurerm_local_network_gateway.this[each.key].id : null
  peer_virtual_network_gateway_id = each.value.type == "Vnet2Vnet" ? each.value.gateway_id : null
  shared_key                      = each.value.shared_key

  dynamic "ipsec_policy" {
    for_each = each.value.ipsec_policy[*]
    content {
      dh_group         = ipsec_policy.value.dh_group
      ike_encryption   = ipsec_policy.value.ike_encryption
      ike_integrity    = ipsec_policy.value.ike_integrity
      ipsec_encryption = ipsec_policy.value.ipsec_encryption
      ipsec_integrity  = ipsec_policy.value.ipsec_integrity
      pfs_group        = ipsec_policy.value.pfs_group
      sa_lifetime      = ipsec_policy.value.sa_lifetime
    }
  }
}

