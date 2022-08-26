resource "azurerm_resource_group" "rg-avd" {
  name     = "avd-multisession-test-ik"
  location = var.location
}

/*
data "azurerm_virtual_network" "ad_vnet_data" {
  name                = "adnet"
  resource_group_name = azurerm_resource_group.rg-avd.name
}

resource "azurerm_virtual_network_peering" "peer1" {
  name                      = "peer_avd_ad"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.ad_vnet_data.id
}

resource "azurerm_virtual_network_peering" "peer2" {
  name                      = "peer_avd_ad"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = "advnet"
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}
*/

resource "time_rotating" "avd_token" {
  rotation_days = 30
}

resource "azurerm_virtual_desktop_host_pool" "avd-hp" {
  location            = azurerm_resource_group.rg-avd.location
  resource_group_name = azurerm_resource_group.rg-avd.name

  name                     = "hostpool-multi"
  friendly_name            = "avdpool"
  validate_environment     = true
  start_vm_on_connect      = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;targetisaadjoined:i:1;"
  description              = "avd host-poool test"
  type                     = "Pooled"
  maximum_sessions_allowed = 50
  load_balancer_type       = "DepthFirst"

  registration_info {
    expiration_date = time_rotating.avd_token.rotation_rfc3339
  }
}

resource "azurerm_virtual_desktop_application_group" "desktopapp" {
  name                = "AVD-Desktop"
  location            = azurerm_resource_group.rg-avd.location
  resource_group_name = azurerm_resource_group.rg-avd.name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd-hp.id
  friendly_name       = "AVD-dapp"
  description         = "A desktop application group"
}

resource "azurerm_virtual_desktop_application_group" "remoteapp" {
  name                = "AVD-Remote"
  location            = azurerm_resource_group.rg-avd.location
  resource_group_name = azurerm_resource_group.rg-avd.name

  type          = "RemoteApp"
  host_pool_id  = azurerm_virtual_desktop_host_pool.avd-hp.id
  friendly_name = "AVD-rapp"
  description   = "A remote application group"
}

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = "AVD-WORKSPACE"
  location            = azurerm_resource_group.rg-avd.location
  resource_group_name = azurerm_resource_group.rg-avd.name
  friendly_name       = "AVD_WORK"
  description         = "Work Purporse"
  depends_on          = [azurerm_virtual_desktop_host_pool.avd-hp]
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "workspaceremoteapp" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.desktopapp.id
}

resource "azurerm_windows_virtual_machine" "avd_sessionhost" {
  depends_on = [
    azurerm_network_interface.sessionhost_nic
  ]
  count               = var.avd_host_pool_size
  name                = "vm-${count.index}"
  resource_group_name = azurerm_resource_group.rg-avd.name
  location            = azurerm_resource_group.rg-avd.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "Password@4231!"
  provision_vm_agent  = true

  network_interface_ids = [azurerm_network_interface.sessionhost_nic.*.id[count.index]]

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "office-365"
    #sku       = "20h2-evd"
    sku     = "win10-21h2-avd-m365"
    version = "latest"
  }
}

locals {
  registration_token = azurerm_virtual_desktop_host_pool.avd-hp.registration_info[0].token
  shutdown_command   = "shutdown -r -t 10"
  exit_code_hack     = "exit 0"
  commandtorun       = "New-Item -Path HKLM:/SOFTWARE/Microsoft/RDInfraAgent/AADJPrivate"
  powershell_command = "${local.commandtorun}; ${local.shutdown_command}; ${local.exit_code_hack}"
}

resource "azurerm_virtual_machine_extension" "AVDModule" {
  depends_on = [
    azurerm_windows_virtual_machine.avd_sessionhost
  ]
  count                = 2
  name                 = "Microsoft.PowerShell.DSC"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_sessionhost.*.id[count.index]
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.73"
  settings             = <<-SETTINGS
    {
        "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_02-23-2022.zip",
        "ConfigurationFunction": "Configuration.ps1\\AddSessionHost",
        "Properties" : {
          "hostPoolName" : "${azurerm_virtual_desktop_host_pool.avd-hp.name}",
          "aadJoin": true
        }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${local.registration_token}"
    }
  }
PROTECTED_SETTINGS

}

resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  depends_on = [
    azurerm_windows_virtual_machine.avd_sessionhost,
    azurerm_virtual_machine_extension.AVDModule
  ]
  count                      = 2
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_sessionhost.*.id[count.index]
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}
resource "azurerm_virtual_machine_extension" "addaadjoin" {
  depends_on = [
    azurerm_virtual_machine_extension.AADLoginForWindows
  ]
  count                = 2
  name                 = "AADJoin"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_sessionhost.*.id[count.index]
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
}
