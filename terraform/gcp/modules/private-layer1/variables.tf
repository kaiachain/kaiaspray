variable "name" {
  type        = string
  description = "Name of every resource's name tag; if empty, auto-generated"
  default     = null
}

variable "network" {
  type        = string
  description = "Network Name to be used"
  default     = ""
}

variable "subnetwork" {
  type        = string
  description = "Subnet Network Name to be used"
  default     = ""
}

variable "zone_list" {
  type        = list(any)
  description = "Available zone lists for selected region"
  default     = []
}

variable "boot_image_id" {
  type        = string
  description = "OS boot image ID"
  default     = "centos-7"
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

variable "ssh_client_ips" {
  type        = list(any)
  description = "SSH ingress IP list"
  default     = []
}

variable "metadata" {
  type        = map(any)
  description = "Metadata array"
}

variable "project_id" {
  type = string
}

variable "create_gcp_firewall_rules" {
  description = "Flag to determine whether to create a GCP firewall rules."
  type        = bool
  default     = true # Enabled by default; set to false to use existing firewall rules
}

variable "network_tags" {
  type        = list(string)
  description = "List of network tags"
  default     = []
}

variable "gcp_region" {
  type        = string
  description = "GCP region where all resources will be created"
  default     = "asia-southeast1"
}

variable "network_tier" {
  type        = string
  description = "Network tier for external IP addresses (PREMIUM or STANDARD)"
  default     = "PREMIUM"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to SSH private key for connecting to instances"
  default     = "~/.ssh/id_rsa"
}

variable "user_name" {
  type        = string
  description = "User name for SSH login to instances"
  default     = "core"
}
