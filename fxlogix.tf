resource "azurerm_storage_account" "FSLogixStorageAccount" {
  name                     = "avdfslogixtest"
  location                 = azurerm_resource_group.rg-avd.location
  resource_group_name      = azurerm_resource_group.rg-avd.name
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind              = "FileStorage"
}

resource "azurerm_storage_share" "FSShare" {
  name                 = "fslogix"
  storage_account_name = azurerm_storage_account.FSLogixStorageAccount.name
  depends_on           = [azurerm_storage_account.FSLogixStorageAccount]
}

data "azurerm_role_definition" "storage_role" {
  name = "Storage File Data SMB Share Contributor"
}

resource "azurerm_role_assignment" "af_role" {
  scope              = azurerm_storage_account.FSLogixStorageAccount.id
  role_definition_id = data.azurerm_role_definition.storage_role.id
  principal_id       = "55f40d7b-2c1b-4254-a406-565ba5334acc"
}