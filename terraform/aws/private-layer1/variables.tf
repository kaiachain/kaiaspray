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
  description = "The options to deploy EN nodes"
  default     = {}
}

variable "deploy_options" {
  type        = any
  description = "The options to deploy kaia nodes"
  default     = {}
}

variable "monitor_options" {
  type        = any
  description = "The options to deploy monitor node"
  default     = {}
}

variable "ssh_existing_private_key_path" {
  type        = string
  description = "Path where the private key is saved. It is only used when create_gcp_key_pair is false."
  default     = ""
}

variable "ssh_existing_public_key_path" {
  type        = string
  description = "Path where the public key is saved. It is only used when create_gcp_key_pair is false."
  default     = ""
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to use for the deployment"
  default     = null
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the deployment"
  default     = []
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to use for the deployment"
  default     = null
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path where the SSH private key will be saved"
  default     = "../../../aws-private-ssh-key.pem"
}