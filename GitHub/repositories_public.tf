module "ansible-playbooks" {
  source          = "./modules/public_repo"
  repository_name = "ansible-playbooks"
}

module "arch-installation" {
  source          = "./modules/public_repo"
  repository_name = "arch-installation"
}

module "archmirror-rsync-client" {
  source          = "./modules/public_repo"
  repository_name = "archmirror-rsync-client"
}

module "archmirror-rsync-server" {
  source          = "./modules/public_repo"
  repository_name = "archmirror-rsync-server"
}

module "bind9" {
  source          = "./modules/public_repo"
  repository_name = "bind9"
}

module "dependatest" {
  source          = "./modules/public_repo"
  repository_name = "dependatest"
}

module "dotfiles" {
  source                 = "./modules/public_repo"
  repository_name        = "dotfiles"
  repository_description = "Personal dotfiles for Linux"
}

module "droidcam-launcher" {
  source          = "./modules/public_repo"
  repository_name = "droidcam-launcher"
}

module "dynbind" {
  source          = "./modules/public_repo"
  repository_name = "dynbind"
}

module "kubectl" {
  source          = "./modules/public_repo"
  repository_name = "kubectl"
}

module "kubernetes" {
  source          = "./modules/public_repo"
  repository_name = "kubernetes"
}

module "kubernetes-presentation" {
  source          = "./modules/public_repo"
  repository_name = "kubernetes-presentation"
}

module "py-camp-rps" {
  source          = "./modules/public_repo"
  repository_name = "py-camp-rps"
}

module "razer-viper-ultimate" {
  source          = "./modules/public_repo"
  repository_name = "razer-viper-ultimate"
}

module "recetas" {
  source          = "./modules/public_repo"
  repository_name = "recetas"
}

module "rsync" {
  source                 = "./modules/public_repo"
  repository_name        = "rsync"
  repository_description = "An Alpine-based container able to execute rsync"
}

module "terraform" {
  source          = "./modules/public_repo"
  repository_name = "terraform"
}

module "torrent-paradise" {
  source          = "./modules/public_repo"
  repository_name = "torrent-paradise"
}

module "ubuntu-prep" {
  source          = "./modules/public_repo"
  repository_name = "ubuntu-prep"
}

module "web" {
  source          = "./modules/public_repo"
  repository_name = "web"
}

module "workflows" {
  source          = "./modules/public_repo"
  repository_name = "workflows"
}
