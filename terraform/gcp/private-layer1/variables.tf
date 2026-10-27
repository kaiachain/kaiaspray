variable "name" {
  type        = string
  description = "Name of every resource's name tag; if empty, auto-generated"
  default     = null
}

variable "compute_disk" {
  type        = any
  description = "Config for additional compute disk"
  default     = null
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

variable "metadata" {
  description = "A map of metadatas to add to all resources"
  default     = {}
}

variable "ssh_client_ips" {
  type        = list(any)
  description = "SSH ingress IP list"
  default     = []
}

variable "create_gcp_key_pair" {
  type        = bool
  description = "Flag to determine whether to create a GCP SSH key pair."
  default     = true
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

variable "project" {
  description = "The name of the project to create or use"
  type        = string
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
  default     = null
}

variable "gcp_region" {
  type        = string
  description = "GCP region where all resources will be created"
  default     = "asia-northeast3"
}

variable "zones" {
  type        = list(string)
  description = "Zones of gcp_region to place the nodes in, in turn; if empty, all of the region's zones (e.g. leave out a zone that has run out of a machine type)"
  default     = []
}

variable "network" {
  type        = string
  description = "Network Name to be used"
  default     = ""
}

variable "subnetwork" {
  type        = string
  description = "Subnet Name to be used"
  default     = ""
}

variable "network_tags" {
  description = "List of network tags to apply to the VPC."
  type        = list(string)
  default     = []
}

variable "create_gcp_firewall_rules" {
  description = "Flag to determine whether to create a GCP firewall rules."
  type        = bool
  default     = true # Enabled by default; set to false to use existing firewall rules
}

variable "user_name" {
  description = "User name to be used for SSH login"
  type        = string
  default     = "kaia"
}
