variable "rg" {
  type        = string
  description = "Resource Group"
}

variable "location" {
  type        = string
  description = "RG location"
}

variable "password" {
  description = "Global Password"
  type        = string
  sensitive   = true
}