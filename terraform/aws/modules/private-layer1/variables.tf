variable "name" {
  type        = string
  description = "Name of every resource's name tag; if empty, auto-generated"
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "aws_region" {
  type        = string
  description = "AWS Region where all resources will be created"
  default     = "ap-northeast-2"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "subnet IDs"
  default     = []
}

variable "ami_id" {
  type        = string
  description = "AMI ID to be used for EC2"
}

variable "key_name" {
  type        = string
  description = "A key pair name used to control login access to EC2 instances"
}

variable "ssh_client_ips" {
  type        = list(string)
  description = "Whitelist IP CIDRs to be used to connect EC2 instances"
  default     = []
}

variable "cn_options" {
  type        = any
  description = "The options to deploy CN nodes"
  default     = {}
}

variable "pn_options" {
  type        = any
  description = "The options to deploy PN nodes"
  default     = {}
}

variable "en_options" {
  type        = any
  description = "The options to deploy PN nodes"
  default     = {}
}

variable "monitor_options" {
  type        = any
  description = "The options to deploy monitor node"
  default     = {}
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to use for the deployment"
  default     = null
}
