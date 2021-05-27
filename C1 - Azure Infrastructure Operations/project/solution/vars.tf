variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "udacit"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "westeurope"
}

variable "vmcount" {
  description = "The number of virtual machines that should be created."
  default = 2
}

variable "username" {
  description = "The linux username used for each virtual machine."
  default = "azureuser"
}

variable "password" {
  description = "The linux password used for each virtual machine."
  default = "APassword11234!"
}