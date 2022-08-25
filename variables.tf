variable "location" {
  default     = "West Europe"
  type        = string
  description = "Azure region for deployments."
}

variable "avd_host_pool_size" {
  default     = 2
  type        = number
  description = "Number of session hosts to add to the AVD host pool."
}

variable "avd_users" {
  description = "AVD users"
  default = [
    "ignacy.katkowski_promise.pl#EXT#@apn365demo.onmicrosoft.com"
  ]
}

variable "aad_group_name" {
  type        = string
  default     = "ikgroup-avd"
  description = "Azure Active Directory Group for AVD users"
}