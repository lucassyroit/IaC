#ECS for region us-east-1
resource "aws_ecs_cluster" "ecs-east" {
  name     = "ecs-east"
  provider = aws


  tags = {
    Name = "ECS us-east"
  }
}


# ECS for region us-west-2
resource "aws_ecs_cluster" "ecs-west" {
  name     = "ecs-west"
  provider = aws.west

  tags = {
    Name = "ECS us-west"
  }
}

# ECS service for the east region
resource "aws_ecs_service" "service-east" {
  provider        = aws
  name            = "service_east"
  cluster         = aws_ecs_cluster.ecs-east.id
  task_definition = aws_ecs_task_definition.service-east.arn
  desired_count   = 0 # Set to 0 to prevent the service from running until the load balancer/ECR image
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [module.vpc-east.private_subnets[0], module.vpc-east.private_subnets[1]]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_sg_east.id, aws_security_group.ecs_instance_sg_east.id]
  }

  load_balancer {
    target_group_arn = module.lb_east.target_group_arns[0]
    container_name   = "service-east-container"
    container_port   = 80
  }

  depends_on = [
    module.lb_west,
    module.lb_east,
    aws_ecs_task_definition.service-east
  ]
}

# ECS service for the west region
resource "aws_ecs_service" "service-west" {
  provider = aws.west

  name            = "service_west"
  cluster         = aws_ecs_cluster.ecs-west.id
  task_definition = aws_ecs_task_definition.service-west.arn
  desired_count   = 0 # Set to 0 to prevent the service from running until the load balancer/ECR image
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [module.vpc-west.private_subnets[0], module.vpc-west.private_subnets[1]]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_sg_west.id]
  }

  load_balancer {
    target_group_arn = module.lb_west.target_group_arns[0]
    container_name   = "service-west-container"
    container_port   = 80
  }

  depends_on = [
    module.lb_west,
    module.lb_east,
    aws_ecs_task_definition.service-west
  ]
}


# Task definition for the ECS service in the east region
resource "aws_ecs_task_definition" "service-east" {
  family                   = "service-east"
  task_role_arn            = data.aws_iam_role.LabRole.arn
  execution_role_arn       = data.aws_iam_role.LabRole.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = <<DEFINITION
  [
    {
      "name": "service-east-container",
      "image": "${aws_ecr_repository.ecr.repository_url}:latest",
      "cpu": 256,
      "memory": 1024,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ]  
    }
  ]
  DEFINITION
}

# Task definition for the ECS service in the west region
resource "aws_ecs_task_definition" "service-west" {
  family                   = "service-west"
  provider                 = aws.west
  network_mode             = "awsvpc"
  task_role_arn            = data.aws_iam_role.LabRole.arn
  execution_role_arn       = data.aws_iam_role.LabRole.arn
  cpu                      = "256"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = <<DEFINITION
  [
    {
      "name": "service-west-container",
      "image": "${aws_ecr_repository.ecr.repository_url}:latest",
      "cpu": 256,
      "memory": 1024,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ]  
    }
  ]
  DEFINITION
}