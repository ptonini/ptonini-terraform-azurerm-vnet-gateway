variable "name" {}

variable "rg" {
  type = object({
    name     = string
    location = string
  })
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
      dh_group         = optional(string)
      ike_encryption   = optional(string)
      ike_integrity    = optional(string)
      ipsec_encryption = optional(string)
      ipsec_integrity  = optional(string)
      pfs_group        = optional(string)
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