output "this" {
  value = azurerm_virtual_network_gateway.this
}

output "subnet_id" {
  value = module.subnet.this.id
}

output "public_ip" {
  value = azurerm_public_ip.this
}

