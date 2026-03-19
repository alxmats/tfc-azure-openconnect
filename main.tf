variable "location" {
  default = "Poland Central"
}
variable "rg_name" {
  default = "rg-tfc"
}

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
}
