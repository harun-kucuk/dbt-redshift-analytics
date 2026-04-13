terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  # Backend config is supplied via -backend-config or a local backend.hcl (not committed).
  # Example: terraform init -backend-config=backend.hcl
  # backend.hcl:
  #   bucket = "<your-state-bucket>"
  #   key    = "redshift-serverless/terraform.tfstate"
  #   region = "<your-region>"
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
