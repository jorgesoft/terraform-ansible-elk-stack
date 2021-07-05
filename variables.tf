variable "username" {
  description = "Global Username"
  type        = string
  default     = "jorges"
}

variable "password" {
  description = "Global Password"
  type        = string
  sensitive   = true
  default     = "password1234!"
}
