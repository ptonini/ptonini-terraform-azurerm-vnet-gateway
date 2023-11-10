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


variable "vnet2vnet_conns" {
  type = map(object({
    gateway_id = string
    shared_key = string
  }))
  default = {}
}

variable "site2site_conns" {
  type = map(object({
    gateway_address = string
    address_space   = set(string)
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

variable "vpn_client" {
  type = object({
    address_space        = set(string)
    vpn_client_protocols = set(string)
    vpn_auth_types       = set(string)
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