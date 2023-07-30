variable "github_token" {
  description = "The token to authenticate to GitHub to perform the Terraform actions"
  type        = string
}

variable "docker_token" {
  description = "The token to authenticate to Docker Hub to push images"
  type        = string
  default     = ""
}
