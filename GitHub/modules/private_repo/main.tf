terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
  }
}

resource "github_repository" "repository" {
  name                   = var.repository_name
  description            = var.repository_description
  visibility             = "private"
  auto_init              = true
  delete_branch_on_merge = true
  allow_auto_merge       = true
  allow_merge_commit     = false
  allow_rebase_merge     = false
  allow_squash_merge     = true
  allow_update_branch    = true
  has_issues             = true
  has_discussions        = false
  has_projects           = false
  has_wiki               = false
}

resource "github_actions_secret" "actions_secret" {
  for_each = var.actions_secrets

  repository      = github_repository.repository.name
  secret_name     = each.key
  plaintext_value = each.value
}

resource "github_actions_variable" "actions_variable" {
  for_each = var.actions_variables

  repository    = github_repository.repository.name
  variable_name = each.key
  value         = each.value
}

resource "github_branch" "main" {
  repository = github_repository.repository.name
  branch     = "main"
}

resource "github_branch_default" "default" {
  repository = github_repository.repository.name
  branch     = github_branch.main.branch
}