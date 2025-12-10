terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.9.0"
    }
  }
}

resource "github_repository" "repository" {
  name                   = var.repository_name
  description            = var.repository_description
  archived               = var.archived
  visibility             = var.visibility
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

resource "github_branch_protection" "main_protection" {
  repository_id = github_repository.repository.node_id

  count = var.visibility == "public" ? 1 : 0

  pattern                         = github_branch.main.branch
  enforce_admins                  = false
  require_signed_commits          = true
  required_linear_history         = true
  require_conversation_resolution = true
  allows_deletions                = false
  allows_force_pushes             = var.main_force_push

  required_status_checks {
    strict   = true
    contexts = var.status_checks
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 0
  }
}
