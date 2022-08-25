data "azuread_client_config" "current" {}

/*resource "azuread_user" "group_owner" {
 user_principal_name = "testpowasd@apn365demo.onmicrosoft.com"
 display_name = "Ignacy Katkowski"
 mail_nickname = "testpaswd"
 password = "SecretP@sswd99!"
}*/

/*data "azuread_user" "aad_user" {
  for_each            = toset(var.avd_users)
  user_principal_name = format("%s", each.key)
}*/

data "azurerm_role_definition" "role" { # access an existing built-in role
  name = "Desktop Virtualization User"
}

/*resource "azuread_group" "aaaad_group" {
  display_name     = "test-avd-grasdsadasp"
  security_enabled = true
   owners = [
 data.azuread_client_config.current.object_id,
 ]
  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      owners,
    ]
  }
}*/

/*resource "azuread_group_member" "aad_group_member" {
  for_each         = data.azuread_user.aad_user
  group_object_id  = azuread_group.aad_group.id
  member_object_id = each.value["id"]
}*/

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

