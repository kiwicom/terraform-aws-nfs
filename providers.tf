terraform {
	backend "s3" {
		bucket = "DUMMY_BUCKET"
		key = "DUMMY_PATH"
		region = "eu-west-1"
		dynamodb_table = "DUMMY_TABLENAME"
		workspace_key_prefix = "workspace"
		role_arn = "DUMMY_ARM"
  }
}

# Setup GZIP provider
provider "gzip" {
  compressionlevel = "BestCompression"
}

# Configure the AWS Provider & AWS related data providers
provider "aws" {
	region = "${var.region}"
	# credentials from ~/.aws/credentials
}

data "aws_region" "current" {
	current = true
}

data "aws_caller_identity" "current" {
	# no arguments
}

data "terraform_remote_state" "base" {
	backend = "s3"
	environment = "prod-eu-west-1"
	config {
		bucket = "DUMMY_BUCKET"
		key = "DUMMY_PATH"
		region = "eu-west-1"
		dynamodb_table = "DUMMY_DYNAMODB_TABLE"
		workspace_key_prefix = "workspace"
		role_arn = "DUMMY_ARN"
	}
}
