module "containers" {
  source                 = "./modules/repository"
  repository_name        = "containers"
  repository_description = "Collection of home-grown, organic, freshly built containers"
}

module "dotfiles" {
  source                 = "./modules/repository"
  repository_name        = "dotfiles"
  repository_description = "My dotfiles collection"
}

module "kubernetes" {
  source                 = "./modules/repository"
  repository_name        = "kubernetes"
  repository_description = "YAML galore"
}

module "kubernetes-presentation" {
  source          = "./modules/repository"
  repository_name = "kubernetes-presentation"
}

module "razer-viper-ultimate" {
  source                 = "./modules/repository"
  repository_name        = "razer-viper-ultimate"
  repository_description = "Python script that sets dock colour depending on mouse battery level"
}

module "scripts" {
  source                 = "./modules/repository"
  repository_name        = "scripts"
  repository_description = "Collection of useful scripts"
}

module "terraform" {
  source                 = "./modules/repository"
  repository_name        = "terraform"
  repository_description = "Terraform scripts for my infrastructure"
}

module "torrent-paradise" {
  source          = "./modules/repository"
  repository_name = "torrent-paradise"
}

module "web" {
  source                 = "./modules/repository"
  repository_name        = "web"
  repository_description = "Personal website accessible at nahue.ar"
}

module "workflows" {
  source                 = "./modules/repository"
  repository_name        = "workflows"
  repository_description = "Reusable GitHub Actions Workflows"
}

module "renovate-test-terraform" {
  source          = "./modules/repository"
  repository_name = "renovate-test-terraform"
  main_force_push = true
}

module "renovate-test-kubernetes" {
  source          = "./modules/repository"
  repository_name = "renovate-test-kubernetes"
  main_force_push = true
}

module "renovate-test-docker" {
  source          = "./modules/repository"
  repository_name = "renovate-test-docker"
  main_force_push = true
}
