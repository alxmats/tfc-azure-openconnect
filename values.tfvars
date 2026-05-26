location       = "Poland Central"
rg_name        = "rg-oc-pc"
public_ip_name = "deboc-ip"
nsgs = {
  "deboc-nsg" = {
    inbound_rules = {
      "SSH" = {
        priority                   = "300"
        protocol                   = "Tcp"
        access                     = "Allow"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_ranges    = ["22"]
      }
      "https" = {
        priority                   = "310"
        protocol                   = "Tcp"
        access                     = "Allow"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_ranges    = ["443"]
      }
      "ICMP" = {

        priority                   = "300"
        protocol                   = "ICMP"
        access                     = "Allow"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_ranges    = ["*"]
      }
    }
    outbound_rules = {}
    subnets        = ["default"]
  }
}
vnets = {
  "deboc-vnet" = {
    address_space = "10.0.0.0/16"
    subnets = {
      "default" = {
        address_prefixes = "10.0.0.0/24"
      }
    }
  }
}
