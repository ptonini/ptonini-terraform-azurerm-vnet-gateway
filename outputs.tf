output "this" {
  value = azurerm_virtual_network_gateway.this
}

output "subnet_id" {
  value = var.subnet == null ? var.subnet_id : module.subnet.this[0].id
}

output "public_ip" {
  value = azurerm_public_ip.this
}

