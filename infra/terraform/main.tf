module "ecr" {
  source = "./modules/ecr"

  app_name              = var.app_name
  image_retention_count = var.image_retention_count
}
