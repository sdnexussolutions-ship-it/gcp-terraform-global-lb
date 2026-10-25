variable "config" {
  description = "Configuration for one ALB, including credentials injected from root sensitive variables."
  type        = any
  sensitive   = false
}
