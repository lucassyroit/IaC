# Load Balancer for East Region
module "lb_east" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  providers = {
    aws = aws
  }

  name               = "loadbalancing-east"
  load_balancer_type = "application"
  vpc_id             = module.vpc-east.vpc_id
  subnets            = module.vpc-east.public_subnets
  security_groups    = [aws_security_group.lb_sg_east.id]

  http_tcp_listeners = [
    {
      port                  = 80,
      protocol              = "HTTP",
      target_group_name     = "webserver-tg-east"
      target_group_port     = 80
      target_group_protocol = "HTTP"
    }
  ]

  target_groups = [
    {
      name             = "webserver-tg-east"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
    }
  ]

}

# Load Balancer for West Region
module "lb_west" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  providers = {
    aws = aws.west
  }

  name               = "loadbalancing-west"
  load_balancer_type = "application"
  vpc_id             = module.vpc-west.vpc_id
  subnets            = module.vpc-west.public_subnets
  security_groups    = [aws_security_group.lb_sg_west.id]

  http_tcp_listeners = [
    {
      port                  = 80,
      protocol              = "HTTP",
      target_group_name     = "webserver-tg-west"
      target_group_port     = 80
      target_group_protocol = "HTTP"
    }
  ]

  target_groups = [
    {
      name             = "webserver-tg-west"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
    }
  ]
}