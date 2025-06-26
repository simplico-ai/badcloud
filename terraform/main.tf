terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.90.1"
    }
  }

  backend "s3" {
    bucket  = "terraform-badcloud-simplico-states"
    key     = "badcloud.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "secure" {
  source = "./modules/secure_infra"

  project_name    = var.project_name
  environment     = var.env
  vpc_id          = aws_vpc.main_vpc.id
  private_subnets = aws_subnet.private[*].id
  vpc_cidr        = aws_vpc.main_vpc.cidr_block
}