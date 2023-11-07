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
  default = "VpnGtw1"
}

variable "vpn_type" {
  default = "RouteBased"
}

variable "vnet" {
  type = object({
    name = string
  })
}

variable "address_prefixes" {
  type = list(string)
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
  default = null

}

variable "custom_routes" {
  default = null
}