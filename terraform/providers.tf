# WARNING: The deployed AWS infrastructure currently tracks the unmerged
# `security/remove-hardcoded-secrets` branch (broker API stack, JWT auth,
# S3 hardening). A `terraform plan` from main proposes ~53 destroys,
# including the live plutus-broker-* Lambdas and S3 bucket protections.
# Do NOT `terraform apply` from main until that branch is merged or the
# migration is explicitly abandoned.

terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "amplify"
}
