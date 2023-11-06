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
  }))
  default = {}
}

variable "vpn_client" {
  default = null

}

variable "custom_routes" {
  default = null
}