variable "location" {
  default = "Poland Central"
}
variable "rg_name" {
  default = "rg-oc-pc"
}
variable "public_ip_name" {
  default = "deboc-ip"
}

variable "vnet_name" {
  default = "deboc-vnet"
}

variable "address_space" {
  default = "deboc-vnet"
}

resource "azurerm_resource_group" "this" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.rg_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_name != null || var.ddos_protection_plan_id != null ? [1] : []

    content {
      id     = try(var.ddos_protection_plan_id, data.azurerm_network_ddos_protection_plan.this[0].id)
      enable = true
    }
  }

  lifecycle {
    ignore_changes = [
      # ddos_protection_plan,
    ]
  }
}

resource "azurerm_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                                          = each.value.name
  resource_group_name                           = var.rg_name
  virtual_network_name                          = azurerm_virtual_network.this.name
  address_prefixes                              = each.value.address_prefixes
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)
  private_endpoint_network_policies             = lookup(each.value, "private_endpoint_network_policies", "Disabled")
  service_endpoints                             = lookup(each.value, "service_endpoints", null)
  service_endpoint_policy_ids                   = lookup(each.value, "service_endpoint_policy_ids", null)

  dynamic "delegation" {
    for_each = try(each.value.delegations, null) != null ? { for set in each.value.delegations : set.service_name => set } : {}

    content {
      name = "delegation-to-${delegation.key}"

      service_delegation {
        name    = delegation.key
        actions = try(delegation.value.actions, [])
      }
    }
  }
}

resource "azurerm_public_ip" "this" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = try(lower(var.name), null)
  tags                = try(var.tags, {})
}

resource "azurerm_network_interface" "this" {
  for_each = { for idx, nic in var.nic_settings : idx => nic }

  name                           = format("%s-NIC%s", var.name, each.key)
  location                       = var.location == null ? data.azurerm_resource_group.this[0].location : var.location
  resource_group_name            = var.rg_name
  tags                           = var.tags == null ? {} : var.tags
  accelerated_networking_enabled = try(each.value.accelerated_networking_enabled, false)
  ip_forwarding_enabled          = try(each.value.ip_forwarding_enabled, false)
  dns_servers                    = try(each.value.dns_servers, [])
  dynamic "ip_configuration" {
    for_each = { for idx, cfg in each.value.ip_configs : idx => cfg }

    content {
      # name                          = try(ip_configuration.value.name, format("%s-%s-ipcfg", var.name, each.key))
      name                          = coalesce(ip_configuration.value.name, format("%s-%s-ipcfg", var.name, each.key))
      primary                       = ip_configuration.value.primary
      subnet_id                     = ip_configuration.value.subnet_id
      public_ip_address_id          = ip_configuration.value.public_ip != null ? azurerm_public_ip.this[each.key].id : null
      private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
      private_ip_address            = ip_configuration.value.private_ip_address
    }
  }

  # ip_configuration {
  #   primary   = try(index(var.nic_settings, each.value), 1) == 0 ? true : false
  #   name      = format("%s-%s-ipcfg", var.name, each.key)
  #   subnet_id = each.value.subnet_id
  #   # subnet_id = try(each.value.subnet_id, data.azurerm_subnet.this[each.value.nic_subnet_name].id)
  #   private_ip_address_allocation = try(each.value.private_ip_allocation_method, "Dynamic")
  #   private_ip_address            = try(each.value.private_ip_allocation_method, "Dynamic") == "Static" ? try(each.value.private_ip_address, null) : null
  #   public_ip_address_id          = each.value.public_ip != null ? azurerm_public_ip.this[each.key].id : null
  # }
}

resource "azurerm_linux_virtual_machine" "vm_linux" {
  count = var.guest_os == "linux" ? 1 : 0

  name                                                   = var.name
  location                                               = var.location == null ? data.azurerm_resource_group.this[0].location : var.location
  resource_group_name                                    = var.rg_name
  size                                                   = var.size
  network_interface_ids                                  = values(azurerm_network_interface.this)[*].id
  computer_name                                          = var.computer_name == null ? var.name : var.computer_name
  admin_username                                         = var.admin_username
  admin_password                                         = var.admin_ssh_public_key == null ? var.admin_password : null
  allow_extension_operations                             = var.provision_vm_agent
  disable_password_authentication                        = var.admin_ssh_public_key == null ? false : true
  zone                                                   = var.zone
  custom_data                                            = var.custom_data_path == null ? null : filebase64(var.custom_data_path)
  tags                                                   = var.tags == null ? {} : var.tags
  source_image_id                                        = var.source_custom_image_id
  patch_mode                                             = var.patch_mode
  patch_assessment_mode                                  = var.patch_assessment_mode
  provision_vm_agent                                     = var.patch_mode == "AutomaticByPlatform" || var.patch_assessment_mode == "AutomaticByPlatform" ? true : var.provision_vm_agent
  bypass_platform_safety_checks_on_user_schedule_enabled = var.patch_mode == "AutomaticByPlatform" ? true : var.bypass_platform_safety_checks_on_user_schedule_enabled

  dynamic "source_image_reference" {
    for_each = var.source_image_reference != null ? [var.source_image_reference] : []

    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = try(source_image_reference.value.version, "latest")
    }
  }

  dynamic "plan" {
    for_each = var.plan != null ? [var.plan] : []

    content {
      name      = plan.value.name
      publisher = plan.value.publisher
      product   = plan.value.product
    }
  }

  os_disk {
    name                 = format("%s-OSD", var.name)
    caching              = var.os_disk_caching
    storage_account_type = var.storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics != null ? [1] : []

    content {
      storage_account_uri = var.boot_diagnostics.storage_account_uri
    }
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "admin_ssh_key" {
    for_each = nonsensitive(var.admin_ssh_public_key) != null ? [1] : []

    content {
      username   = var.admin_username
      public_key = var.admin_ssh_public_key
    }
  }
}