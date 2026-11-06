terraform {
  required_version = ">= 1.9"
}

variable "name" {
  description = "Name used in the greeting"
  type        = string
  default     = "world"
}

output "greeting" {
  description = "Example output"
  value       = "Hello, ${var.name}!"
}
