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
      version = "6.3.1"
    }
  }
}

provider "github" {
  token = var.github_token
}
