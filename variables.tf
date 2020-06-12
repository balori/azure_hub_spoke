variable "location" {
  type    = string
  default = "centralus"
}

variable "rg-name" {
  type    = string
  default = "EU_MRI_leverton_Aks"
}

variable "dev_rg-name" {
  type    = string
  default = "Dev_MRI_leverton_Aks"
}


variable "clustername" {
  type    = string
  default = "terra_Aks_2_aad"
}

variable "dev_location" {
  description = "Location of the network"
  default     = "centralus"
}

variable "username" {
  description = "Username for Virtual Machines"
  default     = "testadmin"
}

variable "password" {
  description = "Password for Virtual Machines"
  default     = "Password1234!"
}

variable "vmsize" {
  description = "Size of the VMs"
  default     = "Standard_DS1_v2"
}

