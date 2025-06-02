variable "github_token" {
  description = "The token to authenticate to GitHub to perform the Terraform actions"
  type        = string
}

variable "docker_token" {
  description = "The token to authenticate to Docker Hub to push images"
  type        = string
  default     = ""
}

variable "TS_OAUTH_ID" {
  description = "value for TS_OAUTH_ID"
  type        = string
  default     = ""
}

variable "TS_OAUTH_SECRET" {
  description = "value for TS_OAUTH_SECRET"
  type        = string
  default     = ""
}

variable "TS_TAILNET" {
  description = "value for TS_TAILNET"
  type        = string
  default     = ""
}
