output "ecr_name" {
    value = aws_ecr_repository.ecr.name
}

output "ecr_url" {
    value = aws_ecr_repository.ecr.repository_url
}

output "ecs_name_east" {
    value = aws_ecs_cluster.ecs-east.name
}

output "ecs_name_west" {
    value = aws_ecs_cluster.ecs-west.name
}

output "ecs_service_name_east" {
    value = aws_ecs_service.service-east.name
}

output "ecs_service_name_west" {
    value = aws_ecs_service.service-west.name
}

output "alb_dns_name_east" {
    value = module.lb_east.this_lb_dns_name
}

output "alb_dns_name_west" {
    value = module.lb_west.this_lb_dns_name
}

output "alb_arn_east" {
    value = module.lb_east.this_lb_arn
}

output "alb_arn_west" {
    value = module.lb_west.this_lb_arn
}

output "rds_id" {
    value = aws_db_instance.db-east-1a.identifier
}

output "rds_name"{
    value = aws_db_instance.db-east-1a.db_name 
}

output "rds_endpoint"{
    value = aws_db_instance.db-east-1a.address
}