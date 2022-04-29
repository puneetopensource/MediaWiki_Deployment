variable "location" {
  type    = string
  default = "<location>"
}

variable "subscription_id" {
  type    = string
  default = "<subscription_id>"
}

variable "tenant_id" {
  type    = string
  default = "<tenant_id>"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "default_tag" {
  default = {
    System = "dev"
  }
}

# variable "keyvault" {
#   type    = string
#   default = "KeyVault-Dev"
# }

variable "resource_group" {
  type    = string
  default = "<resource-group>"
}