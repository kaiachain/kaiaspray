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

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones"
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "create_aws_key_pair" {
  type        = bool
  description = "Flag to create aws key pair or not "
  default     = true
}

variable "key_name" {
  type        = string
  description = "A key pair name used to control login access to EC2 instances; if empty, auto-generated"
  default     = null
}

variable "ssh_client_ips" {
  type        = list(string)
  description = "Whitelist IP CIDRs to be used to connect EC2 instances"
  default     = []
}

variable "deploy_options" {
  type        = any
  description = "The options to deploy kaia nodes"
  default     = {}
}

variable "en_options" {
  type        = any
  description = "The options to deploy EN nodes"
  default     = {}
}

variable "scn_options" {
  type        = any
  description = "The options to deploy SCN nodes"
  default     = {}
}
