module "obsidian" {
  source          = "./modules/repository"
  repository_name = "obsidian"
  visibility      = "private"
}

module "tailscale" {
  source          = "./modules/repository"
  repository_name = "tailscale"
  visibility      = "private"
  actions_secrets = { "TS_OAUTH_ID" : var.TS_OAUTH_ID, "TS_OAUTH_SECRET" : var.TS_OAUTH_SECRET, "TS_TAILNET" : var.TS_TAILNET }
}
