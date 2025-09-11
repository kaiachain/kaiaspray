variable "name" {
  type        = string
  description = "Name of every resource's name tag"
}

variable "ami_id" {
  type        = string
  description = "AMI ID to be used creating instance"
}

variable "instance_type" {
  type        = string
  description = "Instance type to be used creating instance"
}

variable "key_name" {
  type        = string
  description = "A key pair is used to control login access to instance"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to attach to instance"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to place instance"
}

variable "use_eip" {
  type        = bool
  description = "Flag to use EIP; otherwise use auto-associated public IP"
  default     = false
}

variable "root_block_device" {
  type        = any
  description = "Root EBS volumes to attach to instance"
  default     = {}
}

variable "ebs_block_devices" {
  type        = any
  description = "Secondary EBS volumes to attach to instance"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
  default     = {}
}
