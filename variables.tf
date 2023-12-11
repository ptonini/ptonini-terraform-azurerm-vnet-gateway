variable "name" {}

variable "rg" {
  type = object({
    name     = string
    location = string
  })
}

variable "type" {
  default = "Vpn"
}

variable "sku" {
  default = "VpnGw1"
}

variable "vpn_type" {
  default = "RouteBased"
}

variable "subnet" {
  type = object({
    vnet = object({
      name = string
    })
    address_prefixes = list(string)
  })
  default = null
}

variable "subnet_id" {
  default = null
}


variable "connections" {
  type = map(object({
    type = optional(string, "Vnet2Vnet")
    gateway_id = optional(string)
    gateway_address = optional(string)
    address_space   = optional(set(string))
    shared_key      = string
    ipsec_policy = optional(object({
      dh_group         = string
      ike_encryption   = string
      ike_integrity    = string
      ipsec_encryption = string
      ipsec_integrity  = string
      pfs_group        = string
      sa_lifetime      = optional(string)
    }))
  }))
  default = {}
}

variable "vpn_client_configuration" {
  type = object({
    address_space        = set(string)
    protocols            = set(string)
    auth_types           = set(string)
    aad_tenant           = optional(string)
    aad_issuer           = optional(string)
    aad_audience         = optional(string)
    root_certificates    = optional(map(string), {})
    revoked_certificates = optional(map(string), {})
  })
  default = null

}

variable "custom_routes" {
  default = null
}