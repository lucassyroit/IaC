# Security group for the ECS service in the east region
resource "aws_security_group" "ecs_sg_east" {
  provider    = aws
  name        = "ecs_sg_east"
  description = "Allow inbound traffic from the load balancer to the ECS service in the east region"
  vpc_id      = module.vpc-east.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg_east.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for the ECS service in the west region
resource "aws_security_group" "ecs_sg_west" {
  provider    = aws.west
  name        = "ecs_sg_west"
  description = "Allow inbound traffic from the load balancer to the ECS service in the west region"
  vpc_id      = module.vpc-west.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg_west.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for the load balancer in the east region
resource "aws_security_group" "lb_sg_east" {
  provider    = aws
  name        = "lb_sg_east"
  description = "Allow traffic from the Internet to the load balancer in the east region"
  vpc_id      = module.vpc-east.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for the load balancer in the west region
resource "aws_security_group" "lb_sg_west" {

  provider = aws.west

  name        = "lb_sg_west"
  description = "Allow traffic from the Internet to the load balancer in the west region"
  vpc_id      = module.vpc-west.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for the RDS instance in the east region
resource "aws_security_group" "rds_sg_east" {
  provider    = aws
  name        = "rds_sg_east"
  description = "Allow inbound traffic from the ECS service in the east region to the RDS instance"
  vpc_id      = module.vpc-east.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg_east.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for the ECS instance inbound traffic from RDS instance in the east region
resource "aws_security_group" "ecs_instance_sg_east" {
  provider    = aws
  name        = "ecs_instance_sg_east"
  description = "Allow inbound traffic from the RDS instance to the ECS instance in the east region"
  vpc_id      = module.vpc-east.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_sg_east.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow inbound traffic from the VPC"
  vpc_id      = module.vpc-east.vpc_id

  ingress {
    description = "MySQL from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Allow inbound traffic ssh and mysql"
  vpc_id      = module.vpc-east.vpc_id

  ingress {
    description = "MySQL from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
