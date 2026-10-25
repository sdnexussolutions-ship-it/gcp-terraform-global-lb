variable "project_id" {
  type = string
}
variable "region" {
  type = string
}
variable "name" {
  type = string
}
variable "image" {
  type = string
}
variable "container_port" {
  type    = number
  default = 8080
}
