variable "aws_access_key" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in VPC"
  default     = true
}

variable "vpc_cidr_block" {
  type        = string
  description = "Base CIDR Block for VPC"
  default     = "11.0.0.0/16"
}

variable "vpc_public_subnet_lb_cidr_block" {
  type        = string
  description = "CIDR Block for Subnet 1 in VPC"
  default     = "11.0.0.0/24"
}

variable "vpc_private_subnet_asg_cidr_block" {
  type        = string
  description = "CIDR Block for Subnet 1 in VPC"
  default     = "11.0.1.0/24"
}

variable "vpc_private_subnet_rds_cidr_block" {
  type        = string
  description = "CIDR Block for Subnet 2 in VPC"
  default     = "11.0.2.0/24"
}


variable "instance_type" {
  type        = string
  description = "Type for EC2 Instnace"
  default     = "t2.micro"
}

variable "ports" {
  type = map(number)
  default = {
    http  = 80
    https = 443
  }
}