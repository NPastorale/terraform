variable "repository_name" {
  type        = string
  description = "The repository name"
}

variable "repository_description" {
  type        = string
  description = "The repository description"
  default     = ""
}

variable "archived" {
  type        = string
  description = "The archived status"
  default     = false
}

variable "visibility" {
  type        = string
  description = "Whether the repository is private or public"
  default     = "public"
}

variable "actions_secrets" {
  type        = map(any)
  description = "A map of secrets for the repository"
  default     = {}
}

variable "actions_variables" {
  type        = map(any)
  description = "A map of variables for the repository"
  default     = {}
}

variable "status_checks" {
  type        = list(any)
  description = "A list of required status checks"
  default     = []
}
