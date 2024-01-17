module "containers" {
  source                 = "./modules/public_repo"
  repository_name        = "containers"
  repository_description = "Collection of home-grown, organic, freshly built containers"
}

module "dotfiles" {
  source                 = "./modules/public_repo"
  repository_name        = "dotfiles"
  repository_description = "My dotfiles collection"
}

module "kubernetes" {
  source                 = "./modules/public_repo"
  repository_name        = "kubernetes"
  repository_description = "YAML galore"
}

module "kubernetes-presentation" {
  source          = "./modules/public_repo"
  repository_name = "kubernetes-presentation"
}

module "razer-viper-ultimate" {
  source                 = "./modules/public_repo"
  repository_name        = "razer-viper-ultimate"
  repository_description = "Python script that sets dock colour depending on mouse battery level"
}

module "scripts" {
  source                 = "./modules/public_repo"
  repository_name        = "scripts"
  repository_description = "Collection of useful scripts"
}

module "terraform" {
  source                 = "./modules/public_repo"
  repository_name        = "terraform"
  repository_description = "Terraform scripts for my infrastructure"
}

module "torrent-paradise" {
  source          = "./modules/public_repo"
  repository_name = "torrent-paradise"
}

module "web" {
  source                 = "./modules/public_repo"
  repository_name        = "web"
  repository_description = "Personal website accessible at nahue.ar"
}

module "workflows" {
  source                 = "./modules/public_repo"
  repository_name        = "workflows"
  repository_description = "Reusable GitHub Actions Workflows"
}
