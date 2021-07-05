variable "rg" {
  type        = string
  description = "Resource Group"
}

variable "location" {
  type        = string
  description = "RG location"
}

variable "subnet" {
  type        = string
}

variable "username" {
  description = "Global Username"
  type        = string
}

variable "password" {
  description = "Global Password"
  type        = string
  sensitive   = true
}