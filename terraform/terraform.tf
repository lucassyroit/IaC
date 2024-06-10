terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "http" {
    # Specify your HTTP backend configuration if needed
  }
}

# Configure the AWS Provider for us-east-1
provider "aws" {
  region     = "us-east-1"
}

# Configure the AWS Provider for us-west-2
provider "aws" {
  alias      = "west"
  region     = "us-west-2"
}
