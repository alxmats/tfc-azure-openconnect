terraform {
  required_version = ">= 1.1.2"
  # required_providers {
  #   azurerm = {
  #     source  = "hashicorp/azurerm"
  #     version = "~>4.50"
  #   }
  # }
  # backend "azurerm" {}
  cloud {

    organization = "alxmatsorg01"

    workspaces {
      name = "cli-sandbox-01"
    }
  }
}

# terraform {
#   cloud {
#     organization = "{{ORGANIZATION_NAME}}"

#     workspaces {
#       name = "{{WORKSPACE_NAME}}"
#     }
#   }

#   required_version = ">= 1.1.2"
# }

provider "azurerm" {
  use_oidc = true
  features {
    # key_vault {
    #   purge_soft_delete_on_destroy = true
    # }
    # api_management {
    #   purge_soft_delete_on_destroy = true
    # }
    # resource_group {
    #   prevent_deletion_if_contains_resources = false
    # }
  }
}
