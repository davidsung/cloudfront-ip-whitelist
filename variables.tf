variable "environment" {
  description = "Environment"
  default = "staging"
}

variable "aws_region" {
  default = "ap-southeast-1"
}

// VPC
variable "vpc_name" {
  description = "VPC Name"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
}

// Route53
variable "zone_name" {
  description = "Public DNS Domain Name"
}

// Fargate
variable "fargate_cpu" {
  description = "CPU core for Fargate"
  default = 512
}

variable "fargate_memory" {
  description = "Memory for Fargate"
  default = 1024
}

variable "app_image" {
  description = "Container image"
}

variable "app_count" {
  description = "Fargate Replica Count"
  default = 1
}

variable "app_port" {
  description = "Container Port"
  default = 3000
}