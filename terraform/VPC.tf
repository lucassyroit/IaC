# Create a VPC in the east region
module "vpc-east" {
  source = "terraform-aws-modules/vpc/aws"

  providers = {
    aws = aws
  }

  name = "vpc-east"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
}

# Create a VPC in the west region
module "vpc-west" {
  source = "terraform-aws-modules/vpc/aws"

  providers = {
    aws = aws.west
  }

  name = "vpc-west"
  cidr = "10.1.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.3.0/24", "10.1.4.0/24"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc-east" {
  provider = aws
  id       = module.vpc-east.vpc_id

  depends_on = [module.vpc-east]
}

data "aws_vpc" "vpc-west" {
  provider = aws.west
  id       = module.vpc-west.vpc_id

  depends_on = [module.vpc-west]

}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = data.aws_vpc.vpc-east.id
  peer_vpc_id   = data.aws_vpc.vpc-west.id
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_region   = "us-west-2"
  auto_accept   = false

  depends_on = [module.vpc-east, module.vpc-west]
}

# Route for east vpc to west vpc
resource "aws_route" "route-east-to-west" {
  provider                  = aws
  route_table_id            = module.vpc-east.vpc_main_route_table_id
  destination_cidr_block    = module.vpc-west.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

  depends_on = [module.vpc-east, module.vpc-west, aws_vpc_peering_connection.peer]
}

# Route for west vpc to east vpc
resource "aws_route" "route-west-to-east" {
  provider                  = aws.west
  route_table_id            = module.vpc-west.vpc_main_route_table_id
  destination_cidr_block    = module.vpc-east.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

  depends_on = [module.vpc-east, module.vpc-west, aws_vpc_peering_connection.peer]
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.west
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true
}