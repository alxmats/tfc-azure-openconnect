variable "location" {
  default = "Poland Central"
}
variable "rg_name" {
  default = "rg-tfc"
}

resource "azurerm_resource_group" "this" {
  name     = var.rg_name
  location = var.location
}
