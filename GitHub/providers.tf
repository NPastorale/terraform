terraform {
  cloud {
    organization = "Nahue"

    workspaces {
      name = "GitHub"
    }
  }
  required_providers {
    github = {
      source = "integrations/github"
    }
  }
}

provider "github" {
  token = var.github_token
}
