variable "name" {
  type        = string
  description = "Name of every resource's name tag"
}

variable "machine_type" {
  type        = string
  description = "Machine type to be used creating instance"
}

variable "zone" {
  type        = string
  description = "Availability zone for deploy instance"
}

variable "boot_disk" {
  type        = any
  description = "Image ID for deploy instance"
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

variable "use_public_ip" {
  type        = bool
  description = "Flag to use Public IP"
  default     = null
}

variable "compute_disk" {
  type        = any
  description = "Config for additional compute disk"
  default     = null
}

variable "project" {
  type        = string
  description = "GCP Project ID"
  default     = null
}

variable "region" {
  type        = string
  description = "GCP region for resources"
  default     = null
}

variable "network_tier" {
  type        = string
  description = "Network tier for external IP addresses (PREMIUM or STANDARD)"
  default     = "STANDARD"
}

variable "tags" {
  type        = list(any)
  description = "Tag list"
}

variable "metadata" {
  type        = map(any)
  description = "Metadata array"
}

variable "service_account" {
  type = object({
    email  = optional(string)
    scopes = optional(list(string))
  })
  description = "Service account to attach to the instance"
  default     = null
}

variable "spot" {
  type        = bool
  description = "Create a Spot VM, which GCP stops (keeping its disks) when it is preempted"
  default     = false
}

variable "nic_type" {
  type        = string
  description = "NIC type (GVNIC or VIRTIO_NET); null for the GCP default. Machine series such as C4 and N4 need GVNIC"
  default     = null
}
