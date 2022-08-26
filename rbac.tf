data "azuread_client_config" "current" {}


data "azurerm_role_definition" "role" { # access an existing built-in role
  name = "Desktop Virtualization User"
}

resource "azurerm_role_assignment" "role" {
  scope              = azurerm_virtual_desktop_application_group.desktopapp.id
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = "55f40d7b-2c1b-4254-a406-565ba5334acc"
  #azuread_group.aaaad_group.id
}

resource "azurerm_role_assignment" "role2" {
  scope              = azurerm_virtual_desktop_application_group.remoteapp.id
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = "55f40d7b-2c1b-4254-a406-565ba5334acc"
  #azuread_group.aaaad_group.id
}

