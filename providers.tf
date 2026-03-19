terraform {
  required_version = ">= 1.1.2"
  cloud {

    organization = "alxmatsorg01" # "{{ORGANIZATION_NAME}}"

    workspaces {
      name = "cli-sandbox-01" # "{{WORKSPACE_NAME}}"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.50"
    }
  }
}

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
