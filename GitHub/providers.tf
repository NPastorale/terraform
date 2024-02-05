terraform {
  cloud {
    organization = "Nahue"

    workspaces {
      name = "GitHub"
    }
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = "5.45.0"
    }
  }
}

provider "github" {
  token = var.github_token
}
